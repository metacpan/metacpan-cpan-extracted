#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use IO::Socket::INET;
use Time::HiRes ();
use Punk::Test::WS qw(encode_client decode_ref handshake_request);

# A websocket peer that does not read: the server's frames queue once the
# socket is full, a write watcher drains them as the peer catches up, and a
# route with a small write_buffer_limit fails the connection with 1008 when
# the queue outgrows it; and a close handler that dies is reported, not fatal.

BEGIN {
    eval { require Hyperman; 1 } or plan skip_all => 'Hyperman required for these tests';
    eval { require Punk::WebSocket; 1 } or plan skip_all => 'Punk::WebSocket unavailable';
    plan skip_all => 'Hyperman 0.11+ (the detach ABI) required' unless Punk::WebSocket::_hm_available();
}

my $port = 25950 + ($$ % 300);
my $host = "127.0.0.1:$port";
my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDERR, '>', '/dev/null';
    package WSFlood;
    use Punk;
    # a flood the default 16MB queue absorbs: the socket fills, the rest
    # queues, and the write watcher drains it as the client reads
    websocket '/drain' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->send('x' x 65536) for 1 .. 40; $_[0]->send('done') });
    };
    # a flood past a small limit: the connection is failed
    websocket '/small' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->send('y' x 262144) for 1 .. 80 });
        $ws->on(close => sub { die "close handler boom\n" });
    }, { write_buffer_limit => 65536 };
    get '/plain' => sub { $_[0]->text('plain ok') };
    package main;
    Hyperman->run(app => WSFlood->to_app, host => '127.0.0.1', port => $port, workers => 1);
    exit 0;
}
for (1 .. 60) {
    my $s = IO::Socket::INET->new(PeerAddr => $host);
    last if $s;
    Time::HiRes::sleep(0.1);
}
sub ws_connect {
    my ($path) = @_;
    my $s = IO::Socket::INET->new(PeerAddr => $host) or die "connect: $!";
    $s->autoflush(1);
    my ($req) = handshake_request(host => $host, path => $path);
    syswrite $s, $req;
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 5; while (sysread $s, my $c, 1) { $buf .= $c; last if $buf =~ /\r\n\r\n\z/ } alarm 0 };
    return ($s, $buf);
}
sub read_frames {
    my ($s, $secs) = @_;
    my ($buf, @frames) = ('');
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $secs;
        while (1) {
            while (my $f = decode_ref($buf)) { last unless ref $f; substr $buf, 0, $f->{consumed}, ''; push @frames, $f }
            last if @frames && $frames[-1]{opcode} == 8;
            last if @frames && $frames[-1]{opcode} == 1 && $frames[-1]{payload} eq 'done';
            my $n = sysread $s, my $c, 65536;
            last unless $n;
            $buf .= $c;
        }
        alarm 0;
    };
    return @frames;
}

{
    my ($s, $hdr) = ws_connect('/drain');
    like($hdr, qr{^HTTP/1\.1 101 }, 'the drain route upgrades');
    syswrite $s, encode_client(opcode => 1, payload => 'go');
    Time::HiRes::sleep(1.5);                  # let the server fill the socket and queue the rest
    my @f = read_frames($s, 20);
    is(scalar(grep { $_->{opcode} == 1 && length $_->{payload} == 65536 } @f), 40, 'every queued frame arrives once the client reads');
    is($f[-1]{payload}, 'done', 'and the last one closes the flood');
    close $s;
}
{
    my ($s, $hdr) = ws_connect('/small');
    like($hdr, qr{^HTTP/1\.1 101 }, 'the small-buffer route upgrades');
    syswrite $s, encode_client(opcode => 1, payload => 'go');
    Time::HiRes::sleep(1.5);
    my @f = read_frames($s, 20);
    my ($close) = grep { $_->{opcode} == 8 } @f;
    cmp_ok(scalar(grep { $_->{opcode} == 1 } @f), '<', 80, 'the flood is cut short once the queue outgrows its limit');
    ok(!$close || unpack('n', $close->{payload}) == 1008, 'and the close, when it gets out, says 1008');
    close $s;
    my $p = IO::Socket::INET->new(PeerAddr => $host) or die;
    syswrite $p, "GET /plain HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n";
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 5; while (sysread $p, my $c, 4096) { $buf .= $c } alarm 0 };
    like($buf, qr/plain ok\z/, 'a close handler that died did not take the worker with it');
}

kill 'TERM', $pid;
waitpid $pid, 0;
done_testing;
