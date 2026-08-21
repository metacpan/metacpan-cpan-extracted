#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Time::HiRes ();

# SSE FANOUT ACROSS WORKERS.
#
# An SSE stream belongs to the worker that accepted it, exactly as a WebSocket
# does - so an application pushing an event reaches only the fraction of its
# subscribers that happen to be on the worker doing the pushing. The shape is
# identical to the room bug, and until the bus there was no answer to it.
#
# There is no Punk::SSE::Room: an application holds its own streams, which is
# the right thing for SSE, where a stream is usually per user rather than per
# group. What it could not do was reach the other workers. Now it can, with
# $app->subscribe.
#
# This runs a real server with several workers, opens an EventSource-shaped
# connection to each, and pushes ONE event over the bus. Every stream should
# receive it, whichever worker it landed on.

BEGIN {
    eval { require Hyperman; 1 }
        or plan skip_all => 'Hyperman required for these tests';
}
plan skip_all => 'this Hyperman has no message bus (needs hm_abi v5)'
    unless Hyperman->can('bus_init');
plan skip_all => 'fork is POSIX-only here' if $^O eq 'MSWin32';

my $WORKERS = 3;
my $port = 26100 + ($$ % 200);
my $host = "127.0.0.1:$port";

my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDERR, '>', '/dev/null';

    package SSEApp;
    use Punk;

    # Every worker holds its own streams. That is the natural shape for SSE
    # and also the trap: without the bus, only this worker's streams would
    # ever hear anything.
    our @STREAMS;

    sse '/events' => sub {
        my ($c, $stream) = @_;
        push @STREAMS, $stream;
        # tell the client which worker took it, so the test can prove the
        # connections actually spread rather than assume it
        $stream->event(hello => "worker:$$");
    }, { heartbeat => 0 };

    # anything may ask for a push; it reaches every worker
    get '/announce/:msg' => sub {
        my ($c) = @_;
        $c->publish('sse:news' => $c->param('msg'));
        $c->text('published');
    };

    package main;

    # Registered at BOOT, in the parent, before the fork - the only moment a
    # subscription reaches every worker.
    SSEApp->punk_app->subscribe('sse:news' => sub {
        my ($topic, $payload) = @_;
        @SSEApp::STREAMS = grep { $_->is_open } @SSEApp::STREAMS;
        $_->event(news => $payload) for @SSEApp::STREAMS;
    });

    Hyperman->run(app => SSEApp->to_app, host => '127.0.0.1',
                  port => $port, workers => $WORKERS);
    exit 0;
}

for (1 .. 80) {
    my $s = IO::Socket::INET->new(PeerAddr => $host);
    last if $s;
    Time::HiRes::sleep(0.1);
}

sub sock {
    my $s = IO::Socket::INET->new(PeerAddr => $host) or die "connect: $!";
    $s->autoflush(1);
    return $s;
}

# Read whatever has arrived, up to a timeout. SSE is a stream, so this reads
# rather than waiting for a framed message.
sub slurp {
    my ($s, $secs) = @_;
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm($secs || 2);
        while (sysread $s, my $c, 4096) {
            $buf .= $c;
            last if $buf =~ /\n\n\z/;
        }
        alarm 0;
    };
    alarm 0;
    return $buf;
}

sub open_stream {
    my $s = sock();
    syswrite $s, "GET /events HTTP/1.1\r\nHost: $host\r\n"
               . "Accept: text/event-stream\r\n\r\n";
    my $head = slurp($s, 5);
    return $head =~ /text\/event-stream/ ? ($s, $head) : ();
}

# ---- open a stream per worker ------------------------------------------------
# Keep connecting until the streams span more than one worker: with a shared
# listener one worker can take a whole burst, and then a per-worker push would
# satisfy the assertion below while fixing nothing.
my (@streams, %worker_of);
my $attempts = 0;
while ($attempts++ < 40) {
    my ($s, $head) = open_stream();
    next unless $s;
    push @streams, $s;
    $worker_of{$1}++ if $head =~ /worker:(\d+)/;
    last if @streams >= 4 && keys %worker_of > 1;
    Time::HiRes::sleep(0.05);
}

cmp_ok(scalar @streams, '>=', 2, 'several SSE streams opened')
    or BAIL_OUT('could not open streams');

my $spread = keys %worker_of;

SKIP: {
    skip "every stream landed on one worker after $attempts attempts; this "
       . "machine will not spread them, so nothing here could distinguish a "
       . "working bus from a single-worker push", 1
        if $spread < 2;

    # push ONE event, through whichever worker answers this request
    my $t = sock();
    syswrite $t, "GET /announce/hello-sse HTTP/1.1\r\nHost: $host\r\n"
               . "Connection: close\r\n\r\n";
    slurp($t, 3);
    close $t;

    my $heard = grep { slurp($_, 3) =~ /data: hello-sse/ } @streams;

    is($heard, scalar @streams,
        "EVERY SSE stream received the event, across $spread workers - "
      . 'which is what a per-worker push could not do')
        or diag sprintf 'heard %d of %d across %d workers',
                        $heard, scalar @streams, $spread;
}
note "streams spread over $spread worker(s) after $attempts attempts";

close $_ for @streams;
kill 'TERM', $pid;
waitpid $pid, 0;

done_testing;
