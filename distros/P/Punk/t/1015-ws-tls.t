#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use IO::Socket::INET;
use File::Temp ();
use Time::HiRes ();
use PunkWSRef qw(encode_client decode_ref accept_key handshake_request);

# WebSocket over HTTP/1.1 on TLS. An OpenSSL session cannot be detached -
# its state is the server's, not the socket's - so the upgrade rides a 101
# stream handle (the tunnel Hyperman 0.48 added) instead. The RFC 6455 codec
# running over it is the same one the plaintext detach path drives; what is
# new is that the frames travel through SSL_write / SSL_read. This drives a
# real Punk app on a real TLS worker with the independent reference codec.

BEGIN {
    eval { require Hyperman; 1 }
        or plan skip_all => 'Hyperman required for these tests';
    eval { require Punk::WebSocket; 1 }
        or plan skip_all => 'Punk::WebSocket unavailable';
    plan skip_all => 'Hyperman not built with TLS'
        unless Hyperman->can('has_tls') && Hyperman->has_tls;
    plan skip_all => 'the 101 stream tunnel needs Hyperman 0.48+'
        unless eval { Hyperman->VERSION } && Hyperman->VERSION >= 0.48;
    eval { require IO::Socket::SSL; 1 }
        or plan skip_all => 'IO::Socket::SSL required for the TLS client';
}

my $openssl = `which openssl`; chomp $openssl;
plan skip_all => 'openssl CLI not found' unless $openssl;

my $dir  = File::Temp::tempdir(CLEANUP => 1);
my $cert = "$dir/cert.pem";
my $key  = "$dir/key.pem";
system(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout "$key" -out "$cert" }
     . qq{-days 1 -subj "/CN=localhost" >/dev/null 2>&1});
plan skip_all => 'could not create a self-signed cert'
    unless -s $cert && -s $key;

my $port = 25650 + ($$ % 300);
my $host = "127.0.0.1:$port";

my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDERR, '>', '/dev/null';

    package WSApp;
    use Punk;

    # origin => 0: the same-origin defence is exercised in t/1012 and is not
    # what this test is about; here the point is the frames crossing TLS.
    websocket '/echo' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->send("echo:$_[1]") });
        $ws->on(binary  => sub { $_[0]->send_binary("bin:$_[1]") });
    }, { origin => 0 };

    websocket '/proto' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->send('proto:' . ($_[0]->protocol // '-')) });
    }, { origin => 0, protocols => [ 'chat.v2', 'chat.v1' ] };

    get '/plain' => sub { $_[0]->text('plain over tls') };

    package main;
    Hyperman->run(app => WSApp->to_app, host => '127.0.0.1',
                  port => $port, workers => 1, tls_cert => $cert, tls_key => $key);
    exit 0;
}

# wait for the TLS port
for (1 .. 60) {
    my $s = IO::Socket::INET->new(PeerAddr => $host);
    if ($s) { close $s; last }
    Time::HiRes::sleep(0.1);
}

sub tls_sock {
    my $s = IO::Socket::SSL->new(PeerAddr => $host, SSL_verify_mode => 0,
                                 Timeout => 5)
        or return;
    $s->blocking(1);
    return $s;
}

sub read_headers {
    my ($s) = @_;
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        while (sysread $s, my $c, 1) {
            $buf .= $c;
            last if $buf =~ /\r\n\r\n\z/;
        }
        alarm 0;
    };
    return $buf;
}

sub read_frame {
    my ($s) = @_;
    my $buf = \${*$s}{ws_buf};
    $$buf //= '';
    my $f;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        while (1) {
            $f = decode_ref($$buf);
            last if $f && ref $f;
            my $n = sysread $s, my $c, 4096;
            last unless $n;
            $$buf .= $c;
        }
        alarm 0;
    };
    return undef unless ref $f;
    substr $$buf, 0, $f->{consumed}, '';
    return $f;
}

# ---- the handshake over TLS -----------------------------------------------

my $s = tls_sock();
ok($s, 'TLS handshake with the worker succeeded') or do {
    kill 'TERM', $pid; waitpid $pid, 0;
    done_testing; exit;
};

my ($req, $wskey) = handshake_request(host => $host, path => '/echo');
syswrite $s, $req;
my $hdr = read_headers($s);
like($hdr, qr{^HTTP/1\.1 101 }, 'a 101 came back over the TLS connection');
like($hdr, qr/^Upgrade:\s*websocket/mi, 'with the Upgrade header');
like($hdr, qr/^Connection:\s*Upgrade/mi, 'and Connection: Upgrade, not close');
unlike($hdr, qr/^Connection:\s*close/mi, 'never a Connection: close on the 101');
my ($accept) = $hdr =~ /Sec-WebSocket-Accept:\s*(\S+)/i;
is($accept, accept_key($wskey),
   'the Sec-WebSocket-Accept is the digest of our key, so the codec is live');

# ---- frames both ways through the session ---------------------------------

syswrite $s, encode_client(opcode => 1, payload => 'over tls');
my $f = read_frame($s);
is($f && $f->{opcode}, 1, 'a text frame came back');
is($f && $f->{payload}, 'echo:over tls',
   'the message crossed TLS to the handler and its reply crossed back');

syswrite $s, encode_client(opcode => 2, payload => 'bytes');
$f = read_frame($s);
is($f && $f->{opcode}, 2, 'a binary frame came back as binary');
is($f && $f->{payload}, 'bin:bytes', 'with the bytes intact through the session');

# ---- the closing handshake ------------------------------------------------

syswrite $s, encode_client(opcode => 8, payload => "\x03\xe8");   # 1000
$f = read_frame($s);
is($f && $f->{opcode}, 8, 'the server answered the close with a close');
close $s;

# ---- a subprotocol is negotiated on the tunnel too ------------------------

$s = tls_sock();
ok($s, 'a second TLS connection');
($req, $wskey) = handshake_request(host => $host, path => '/proto',
                                   protocol => 'chat.v1');
syswrite $s, $req;
$hdr = read_headers($s);
like($hdr, qr{^HTTP/1\.1 101 }, 'the subprotocol route also upgraded');
like($hdr, qr/^Sec-WebSocket-Protocol:\s*chat\.v1/mi,
     'the negotiated subprotocol rode out in the 101 headers');
syswrite $s, encode_client(opcode => 1, payload => 'x');
$f = read_frame($s);
is($f && $f->{payload}, 'proto:chat.v1',
   'and the handler saw it as the connection subprotocol');
close $s;

# ---- ordinary HTTPS is untouched by all of this ---------------------------

{
    my $h = tls_sock();
    ok($h, 'a plain HTTPS request connects');
    syswrite $h, "GET /plain HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n";
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        while (sysread $h, my $c, 4096) { $buf .= $c }
        alarm 0;
    };
    like($buf, qr/plain over tls/, 'a normal HTTPS response still works');
    close $h;
}

kill 'TERM', $pid;
waitpid $pid, 0;
done_testing;
