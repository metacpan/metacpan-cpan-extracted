#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use IO::Socket::INET;
use Time::HiRes ();
use PunkWSRef qw(encode_client decode_ref handshake_request);

# What a connection costs the worker that holds it.
#
# A message is handed to its handler from a callback the event loop calls
# straight into C, with no temporaries frame around it. Anything made mortal
# there before a frame was opened stayed allocated until the worker exited,
# so a worker's memory grew by the size of everything it had ever been sent.
# The numbers are the worker's own resident size, read from outside it.

BEGIN {
    eval { require Hyperman; 1 }
        or plan skip_all => 'Hyperman required for these tests';
    eval { require Punk::WebSocket; 1 }
        or plan skip_all => 'Punk::WebSocket unavailable';
    plan skip_all => 'Hyperman 0.11+ (the detach ABI) required'
        unless Punk::WebSocket::_hm_available();
    plan skip_all => 'needs fork and ps' if $^O eq 'MSWin32';
}

my $port = 26100 + ($$ % 300);
my $host = "127.0.0.1:$port";

my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDERR, '>', '/dev/null';
    package MemApp;
    use Punk;
    websocket '/sink' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { });
        $ws->on(binary  => sub { });
        $ws->on(ping    => sub { });
    }, { origin => 0 };
    websocket '/count' => sub {
        my ($c, $ws) = @_;
        my $n = 0;
        $ws->on(binary  => sub { $n++ });
        $ws->on(message => sub { $_[0]->send("count:$n") });
    }, { origin => 0 };
    get '/plain' => sub { $_[0]->text('ok') };
    package main;
    Hyperman->run(app => MemApp->to_app, host => '127.0.0.1', port => $port,
                  workers => 1);
    exit 0;
}
for (1 .. 80) {
    last if IO::Socket::INET->new(PeerAddr => $host);
    Time::HiRes::sleep(0.1);
}

sub worker_pid { my @k = split ' ', (`pgrep -P $pid` // ''); return $k[0] // $pid }
sub rss_mb {
    my $w = worker_pid();
    my ($r) = (`ps -o rss= -p $w` // '') =~ /(\d+)/;
    return defined $r ? int($r / 1024) : undef;
}
sub ws_connect {
    my ($path) = @_;
    my $s = IO::Socket::INET->new(PeerAddr => $host) or return undef;
    $s->autoflush(1);
    print {$s} handshake_request(path => $path, host => $host);
    my $resp = '';
    while ($resp !~ /\r\n\r\n/) {
        sysread($s, my $b, 4096) or return undef;
        $resp .= $b;
    }
    return $resp =~ m{^HTTP/1\.1 101} ? $s : undef;
}
sub write_all {
    my ($s, $bytes) = @_;
    my $off = 0;
    while ($off < length $bytes) {
        my $n = syswrite($s, $bytes, length($bytes) - $off, $off);
        return 0 unless defined $n;
        $off += $n;
    }
    return 1;
}
sub next_frame {
    my ($s, $secs) = @_;
    my $buf = '';
    my $f;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $secs;
        while (!($f = decode_ref($buf))) {
            sysread($s, my $b, 65536) or last;
            $buf .= $b;
        }
        alarm 0;
    };
    alarm 0;
    return ref $f ? $f : undef;
}

plan skip_all => 'cannot read the worker\'s resident size here'
    unless defined rss_mb();

# ---- received messages are not kept --------------------------------------------
{
    my $s = ws_connect('/sink') or BAIL_OUT('no websocket');
    my $frame = encode_client(opcode => 2, payload => 'x' x 65536);
    my $batch = sub {
        my ($tag) = @_;
        write_all($s, $frame) or die "write: $!" for 1 .. 1000;
        write_all($s, encode_client(opcode => 9, payload => $tag));
        my $f = next_frame($s, 30);
        return $f && $f->{opcode} == 10 && $f->{payload} eq $tag;
    };
    ok($batch->('warm'), 'a thousand 64 KB messages are received');
    my $before = rss_mb();
    ok($batch->("b$_"), "and another thousand ($_)") for 1 .. 3;
    my $grew = rss_mb() - $before;
    cmp_ok($grew, '<', 40,
        "187 MB of messages grew the worker by ${grew} MB");
    # Not only "no more than last time": a sender that outruns the handler
    # must not have its backlog held as live messages either, which grows
    # the worker once and then stays, so a difference would not show it.
    my $now = rss_mb();
    cmp_ok($now, '<', 60,
        "and after 250 MB of them the worker is ${now} MB in all");

    # text, and the ping handler's own argument
    my $text = encode_client(opcode => 1, payload => 'y' x 60000);
    my $ping = encode_client(opcode => 9, payload => 'p' x 125);
    write_all($s, $text) for 1 .. 300;
    write_all($s, $ping) for 1 .. 300;
    1 while next_frame($s, 1);
    $before = rss_mb();
    for my $round (1 .. 3) {
        write_all($s, $text . $ping) for 1 .. 600;
        write_all($s, encode_client(opcode => 1, payload => 'sync'));
        1 while next_frame($s, 1);
    }
    $grew = rss_mb() - $before;
    cmp_ok($grew, '<', 40,
        "108 MB of text and 1800 pings grew the worker by ${grew} MB");
    close $s;
}

# ---- a fast sender of small messages is not one message too big ----------------
# Everything it had ready used to be read before any of it was handed on, and
# the cap on one message was applied to that whole backlog.
{
    my $s = ws_connect('/count') or BAIL_OUT('no websocket');
    my $frame = encode_client(opcode => 2, payload => 'z' x 4000);
    my $n = 8000;                                  # 32 MB, twice the cap
    my $blast = $frame x 200;
    write_all($s, $blast) or last for 1 .. $n / 200;
    write_all($s, encode_client(opcode => 1, payload => 'how many'));
    my $f = next_frame($s, 30);
    ok($f, 'the connection answers after 32 MB of 4000-byte frames');
    is($f ? $f->{opcode} : -1, 1, '...with a message, not a close');
    is($f ? $f->{payload} : '', "count:$n", '...having handed on every frame');
    close $s;
}

# ---- and the worker is still serving -------------------------------------------
{
    my $s = IO::Socket::INET->new(PeerAddr => $host);
    print {$s} "GET /plain HTTP/1.1\r\nHost: $host\r\nConnection: close\r\n\r\n";
    my $resp = do { local $/; <$s> };
    like($resp, qr{^HTTP/1\.1 200 }, 'ordinary HTTP is answered afterwards');
}

kill 'TERM', $pid;
waitpid $pid, 0;

done_testing;
