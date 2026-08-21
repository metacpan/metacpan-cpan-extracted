#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use IO::Socket::INET;
use Time::HiRes ();
use PunkWSRef qw(encode_client decode_ref accept_key handshake_request);

# WebSockets end to end: a real Punk app on a real Hyperman worker, driven
# by the independent reference codec in t/lib. Covers the upgrade
# handshake and its rejections, echo, rooms, ping/pong, the closing
# handshake, guards running before the upgrade, and the worker staying
# healthy for ordinary HTTP throughout.

BEGIN {
    eval { require Hyperman; 1 }
        or plan skip_all => 'Hyperman required for these tests';
    eval { require Punk::WebSocket; 1 }
        or plan skip_all => 'Punk::WebSocket unavailable';
    plan skip_all => 'Hyperman 0.11+ (the detach ABI) required'
        unless Punk::WebSocket::_hm_available();
}

my $port = 25300 + ($$ % 300);
my $host = "127.0.0.1:$port";

my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDERR, '>', '/dev/null';
    require Punk::WebSocket::Room;

    package WSApp;
    use Punk;

    websocket '/echo' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->send("echo:$_[1]") });
        $ws->on(binary  => sub { $_[0]->send_binary("bin:$_[1]") });
        $ws->on(ping    => sub { });      # the pong is automatic
    };

    websocket '/chat' => sub {
        my ($c, $ws) = @_;
        my $room = Punk::WebSocket::Room->named('lobby');
        $ws->on(open    => sub { $room->join($_[0]) });
        $ws->on(message => sub { $room->broadcast("said:$_[1]") });
        $ws->on(close   => sub { $room->leave($_[0]) });
    };

    websocket '/proto' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->send('proto:' . ($_[0]->protocol // '-')) });
    }, { protocols => [ 'chat.v2', 'chat.v1' ] };

    my $guarded = under '/private' => sub {
        my ($c) = @_;
        return $c->text('nope', 403)
            unless ($c->req->header('x-token') // '') eq 'let-me-in';
        return;
    };
    $guarded->websocket('/ws' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->send('guarded ok') });
    });

    get '/plain' => sub { $_[0]->text('plain ok') };

    package main;
    Hyperman->run(app => WSApp->to_app, host => '127.0.0.1',
                  port => $port, workers => 1);
    exit 0;
}

for (1 .. 60) {
    my $s = IO::Socket::INET->new(PeerAddr => $host);
    last if $s;
    Time::HiRes::sleep(0.1);
}

sub sock {
    my $s = IO::Socket::INET->new(PeerAddr => $host) or die "connect: $!";
    $s->autoflush(1);
    return $s;
}

# Read until a full HTTP header block has arrived.
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

# Open a connection and complete the handshake; returns (socket, headers).
sub ws_connect {
    my (%a) = @_;
    my $s = sock();
    my ($req, $key) = handshake_request(host => $host, %a);
    syswrite $s, $req;
    my $hdr = read_headers($s);
    return ($s, $hdr, $key);
}

# Read one frame off the wire.
sub read_frame {
    my ($s) = @_;
    my $buf = '';
    my $f;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        while (1) {
            $f = decode_ref($buf);
            last if $f && ref $f;
            my $n = sysread $s, my $c, 4096;
            last unless $n;
            $buf .= $c;
        }
        alarm 0;
    };
    return ref $f ? $f : undef;
}

sub http_get {
    my ($path) = @_;
    my $s = sock();
    syswrite $s, "GET $path HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n";
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        while (my $n = sysread $s, my $c, 4096) { $buf .= $c }
        alarm 0;
    };
    return $buf;
}

# ---- the handshake ---------------------------------------------------------
{
    my ($s, $hdr, $key) = ws_connect(path => '/echo');
    like($hdr, qr{\AHTTP/1\.1 101 Switching Protocols\r\n},
        'the upgrade is answered with a real 101');
    like($hdr, qr/Upgrade: websocket/i, 'Upgrade header');
    like($hdr, qr/Connection: Upgrade/i, 'Connection header');
    my ($acc) = $hdr =~ /Sec-WebSocket-Accept: (\S+)/i;
    is($acc, accept_key($key), 'Sec-WebSocket-Accept is the RFC 6455 digest');
    close $s;
}

# ---- echo, binary, ping/pong, close ---------------------------------------
{
    my ($s) = ws_connect(path => '/echo');

    syswrite $s, encode_client(opcode => 1, payload => 'hello');
    my $f = read_frame($s);
    is($f->{opcode}, 1, 'a text frame comes back');
    is($f->{payload}, 'echo:hello', 'echoed through the handler');
    is($f->{masked}, 0, 'server frames are not masked');

    syswrite $s, encode_client(opcode => 2, payload => 'raw');
    $f = read_frame($s);
    is($f->{opcode}, 2, 'binary stays binary');
    is($f->{payload}, 'bin:raw', 'binary handler ran');

    syswrite $s, encode_client(opcode => 9, payload => 'hi');
    $f = read_frame($s);
    is($f->{opcode}, 10, 'a ping is answered with a pong');
    is($f->{payload}, 'hi', 'the pong echoes the ping payload');

    # a fragmented text message
    syswrite $s, encode_client(opcode => 1, fin => 0, payload => 'frag');
    syswrite $s, encode_client(opcode => 0, fin => 1, payload => 'ment');
    $f = read_frame($s);
    is($f->{payload}, 'echo:fragment', 'fragments reassemble into one message');

    # clean close: the server echoes it
    syswrite $s, encode_client(opcode => 8, payload => pack('n', 1000) . 'bye');
    $f = read_frame($s);
    is($f->{opcode}, 8, 'the close is echoed');
    is(unpack('n', substr $f->{payload}, 0, 2), 1000, 'with the same code');
    close $s;
}

# ---- utf8 and protocol violations close with the right codes ---------------
{
    my ($s) = ws_connect(path => '/echo');
    syswrite $s, encode_client(opcode => 1, payload => "bad \xff\xfe utf8");
    my $f = read_frame($s);
    is($f->{opcode}, 8, 'invalid utf8 in a text frame closes the connection');
    is(unpack('n', substr $f->{payload}, 0, 2), 1007, 'with close code 1007');
    close $s;
}
{
    my ($s) = ws_connect(path => '/echo');
    # an unmasked client frame is a protocol error
    syswrite $s, PunkWSRef::encode_server(opcode => 1, payload => 'nope');
    my $f = read_frame($s);
    is($f->{opcode}, 8, 'an unmasked client frame closes the connection');
    is(unpack('n', substr $f->{payload}, 0, 2), 1002, 'with close code 1002');
    close $s;
}

# ---- rooms -----------------------------------------------------------------
{
    my ($a) = ws_connect(path => '/chat');
    my ($b) = ws_connect(path => '/chat');
    Time::HiRes::sleep(0.2);        # let both opens land

    syswrite $a, encode_client(opcode => 1, payload => 'hey');
    my $to_a = read_frame($a);
    my $to_b = read_frame($b);
    is($to_a->{payload}, 'said:hey', 'the sender sees the broadcast');
    is($to_b->{payload}, 'said:hey', 'the other member sees it too');
    close $a;
    close $b;
}

# ---- subprotocol negotiation ------------------------------------------------
{
    my ($s, $hdr) = ws_connect(path => '/proto', protocol => 'chat.v1, x.y');
    like($hdr, qr/Sec-WebSocket-Protocol: chat\.v1/i,
        'the offered subprotocol the route supports is selected');
    syswrite $s, encode_client(opcode => 1, payload => 'q');
    is(read_frame($s)->{payload}, 'proto:chat.v1',
        'and reaches the handler');
    close $s;

    my ($s2, $hdr2) = ws_connect(path => '/proto', protocol => 'nope.v9');
    like($hdr2, qr{\AHTTP/1\.1 400}, 'an unsupported subprotocol is a 400');
    close $s2;
}

# ---- handshake rejections ---------------------------------------------------
{
    my ($s, $hdr) = ws_connect(path => '/echo', version => 8);
    like($hdr, qr{\AHTTP/1\.1 426}, 'a wrong version is a 426');
    like($hdr, qr/Sec-WebSocket-Version: 13/i, 'advertising version 13');
    close $s;
}
{
    my ($s, $hdr) = ws_connect(path => '/echo', key => '');
    like($hdr, qr{\AHTTP/1\.1 400}, 'a missing key is a 400');
    close $s;
}
{
    my $s = sock();
    syswrite $s, "GET /echo HTTP/1.1\r\nHost: $host\r\nConnection: close\r\n\r\n";
    like(read_headers($s), qr{\AHTTP/1\.1 400},
        'a plain GET on a websocket route is a 400');
    close $s;
}

# ---- guards run before the upgrade -----------------------------------------
{
    my ($s, $hdr) = ws_connect(path => '/private/ws');
    like($hdr, qr{\AHTTP/1\.1 403},
        'a guard rejects with an ordinary HTTP response, pre-upgrade');
    close $s;

    my ($s2, $hdr2) = ws_connect(path => '/private/ws',
        extra => [ 'X-Token: let-me-in' ]);
    like($hdr2, qr{\AHTTP/1\.1 101}, 'and lets an authorised client upgrade');
    syswrite $s2, encode_client(opcode => 1, payload => 'x');
    is(read_frame($s2)->{payload}, 'guarded ok', 'the guarded socket works');
    close $s2;
}

# ---- ordinary HTTP is unaffected throughout ---------------------------------
{
    my ($held) = ws_connect(path => '/echo');
    like(http_get('/plain'), qr/plain ok/,
        'plain routes serve while a websocket is open');
    syswrite $held, encode_client(opcode => 1, payload => 'still');
    is(read_frame($held)->{payload}, 'echo:still',
        'and the websocket still works afterwards');
    close $held;
    like(http_get('/plain'), qr/plain ok/, 'worker healthy at the end');
}

kill 'TERM', $pid;
waitpid $pid, 0;

done_testing();
