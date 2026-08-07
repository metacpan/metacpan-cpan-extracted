#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Socket;
use Time::HiRes ();

# Server-Sent Events. The field formatting and the blocking / psgi.streaming
# transports run in-process; the detach transport runs against a real Hyperman
# worker (the t/21-ws-live.t harness) and proves it streams without pinning it.

use Punk::SSE;

# ---- blocking transport + field formatting ----------------------------------
# A blocking SSE handler streams synchronously over psgix.io; a socketpair
# stands in for the client so we can read the exact bytes.
{
    package BApp;
    use Punk;
    sse '/stream' => sub {
        my ($c, $s) = @_;
        $s->send('hello');            # data: hello
        $s->send("a\nb");             # multi-line -> two data: lines
        $s->send({ x => 1 });         # a ref -> JSON
        $s->comment('ka');            # : ka
        $s->id(42);                   # id: 42
        $s->retry(1000);              # retry: 1000
        $s->event(tick => 'hi');      # event: tick / data: hi
        $s->close;
    }, { blocking => 1 };
    package main;

    my $app = BApp->to_app;
    socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
    my $r = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/stream',
                     'psgix.io' => $theirs });
    close $theirs;
    is($r->[0], 200, 'blocking sse returns a 200 sentinel triplet');

    my $raw = '';
    eval { local $SIG{ALRM} = sub { die "to\n" }; alarm 2;
           while (sysread $ours, my $c, 4096) { $raw .= $c } alarm 0 };
    my ($head, $body) = split /\r\n\r\n/, $raw, 2;
    like($head, qr{^HTTP/1\.1 200 OK}, 'the HTTP status line');
    like($head, qr{Content-Type: text/event-stream}, 'the event-stream content type');
    like($head, qr{Cache-Control: no-cache}, 'no-cache');

    is($body,
       "data: hello\n\n"
     . "data: a\ndata: b\n\n"
     . "data: {\"x\":1}\n\n"
     . ": ka\n"
     . "id: 42\n"
     . "retry: 1000\n"
     . "event: tick\ndata: hi\n\n",
       'every field is formatted byte-exact to the spec');
}

# ---- psgi.streaming transport ------------------------------------------------
{
    package SApp;
    use Punk;
    sse '/s' => sub { my ($c, $s) = @_; $s->send('hi'); $s->close };
    package main;

    my $app = SApp->to_app;
    my $r = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/s',
                     'psgi.streaming' => 1 });
    is(ref $r, 'CODE', 'a psgi.streaming server gets a delayed-response coderef');

    my ($status, %hdr, @writes, $closed);
    $r->(sub {
        my $sh = shift;
        $status = $sh->[0];
        %hdr = @{ $sh->[1] };
        return TestWriter->new(\@writes, \$closed);
    });
    is($status, 200, 'the responder is called with a 200');
    is($hdr{'Content-Type'}, 'text/event-stream', 'and the event-stream headers');
    like(join('', @writes), qr/data: hi\n\n/, 'the writer receives the event');
    ok($closed, 'and close is called when the stream ends');

    package TestWriter;
    sub new   { bless { w => $_[1], c => $_[2] }, $_[0] }
    sub write { push @{ $_[0]{w} }, $_[1] }
    sub close { ${ $_[0]{c} } = 1 }
}

# ---- detach transport, on a real Hyperman worker ----------------------------
SKIP: {
    eval { require Hyperman; require Punk::WebSocket; 1 }
        or skip 'Hyperman required for the loop tests', 1;
    require IO::Socket::INET;
    skip 'Hyperman 0.11+ (a live loop) required', 1
        unless Punk::WebSocket::_hm_available();

    my $port = 26400 + ($$ % 300);
    my $host = "127.0.0.1:$port";
    my $pid  = fork // die "fork: $!";
    if (!$pid) {
        close STDERR;
        package LApp;
        use Punk;
        our $CLOSED = 0;
        sse '/events' => sub {
            my ($c, $s) = @_;
            $s->on(close => sub { $CLOSED++ });
            my $n = 0; my $tick;
            $tick = sub {
                return unless $s->is_open;
                $s->send({ n => ++$n });
                $c->timer(0.1)->on_done($tick) if $n < 20;
            };
            $tick->();
        }, { heartbeat => 0.2 };
        get '/fast'   => sub { $_[0]->text('fast') };
        get '/closed' => sub { $_[0]->text($LApp::CLOSED) };
        package main;
        Hyperman->run(app => LApp->to_app, host => '127.0.0.1',
                      port => $port, workers => 1);
        exit 0;
    }
    for (1 .. 60) {
        my $s = IO::Socket::INET->new(PeerAddr => $host);
        last if $s;
        Time::HiRes::sleep(0.1);
    }
    my $plain = sub {
        my ($p) = @_;
        my $s = IO::Socket::INET->new(PeerAddr => $host) or return '';
        $s->autoflush(1);
        syswrite $s, "GET $p HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n";
        my $b = '';
        eval { local $SIG{ALRM} = sub { die "to\n" }; alarm 3;
               while (sysread $s, my $c, 4096) { $b .= $c } alarm 0 };
        $b =~ s/.*\r\n\r\n//s;
        return $b;
    };

    # open the stream, and hit /fast while it is live
    my $es = IO::Socket::INET->new(PeerAddr => $host) or die "connect: $!";
    $es->autoflush(1);
    syswrite $es, "GET /events HTTP/1.1\r\nHost: x\r\n\r\n";
    my $t0 = Time::HiRes::time();
    is($plain->('/fast'), 'fast', 'a plain request is served while the stream is open');
    ok(Time::HiRes::time() - $t0 < 0.5, 'and served promptly (worker not pinned)');

    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "to\n" }; alarm 1;
           while (sysread $es, my $c, 4096) { $buf .= $c } alarm 0 };
    like($buf, qr{^HTTP/1\.1 200 OK}, 'the stream opens with a 200');
    like($buf, qr{Content-Type: text/event-stream}, 'as an event stream');
    my $events = () = $buf =~ /^data: /mg;
    ok($events >= 3, "several events arrived over the loop ($events)");
    like($buf, qr/^:$/m, 'a heartbeat comment arrived');

    # drop the client; the worker should fire on(close)
    close $es;
    Time::HiRes::sleep(0.4);
    ok($plain->('/closed') >= 1, 'dropping the client fired on(close) in the worker');

    kill 9, $pid; waitpid $pid, 0;
}

done_testing;
