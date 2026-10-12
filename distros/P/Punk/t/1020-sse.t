#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Socket;
use Time::HiRes ();
use POSIX ();

# Server-Sent Events. The field formatting and the blocking / psgi.streaming
# transports run in-process; the detach transport runs against a real Hyperman
# worker (the t/1011-ws-live.t harness) and proves it streams without pinning it.

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

# ---- a line break is CR, LF or CRLF --------------------------------------------
# The client ends a line at any of the three. A CR left inside a data: line
# is where the next field starts for it, so text relayed from a user could
# name the event and set the last event id for everyone listening.
{
    package CRApp;
    use Punk;
    sse '/stream' => sub {
        my ($c, $s) = @_;
        $s->send("user text\rid: 999\revent: admin\rdata: injected");
        $s->send("a\r\nb");
        $s->send("tail\r");
        $s->send("x\n\ry");
        $s->event(tick => "one\rtwo");
        $s->close;
    }, { blocking => 1 };
    package main;

    socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
    CRApp->to_app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/stream',
                      'psgix.io' => $theirs });
    close $theirs;
    my $raw = '';
    eval { local $SIG{ALRM} = sub { die "to\n" }; alarm 2;
           while (sysread $ours, my $c, 4096) { $raw .= $c } alarm 0 };
    my (undef, $body) = split /\r\n\r\n/, $raw, 2;
    unlike($body, qr/\r/, 'no CR reaches the wire');
    is($body,
       "data: user text\ndata: id: 999\ndata: event: admin\ndata: data: injected\n\n"
     . "data: a\ndata: b\n\n"
     . "data: tail\ndata: \n\n"
     . "data: x\ndata: \ndata: y\n\n"
     . "event: tick\ndata: one\ndata: two\n\n",
       'CR and CRLF each end a data line, like LF');
    my @fields = map { (split /:/, $_, 2)[0] } grep { length } split /\n/, $body;
    is_deeply([ grep { $_ ne 'data' && $_ ne 'event' } @fields ], [],
        '...so a client sees data lines and the one event it was sent, nothing else');
    is(scalar(grep { $_ eq 'event' } @fields), 1, '...and only that one event name');
}

# ---- HEAD is the headers ------------------------------------------------------
{
    my $ran = 0;
    package HeadApp;
    use Punk;
    sse '/events' => sub { $ran++; $_[1]->send('never') };
    get '/csv' => sub {
        $_[0]->stream('text/csv', { status => 201,
            headers => [ 'X-Rows' => 3 ] }, sub { $ran++; $_[1]->write("a\n") });
    };
    package main;

    my $app = HeadApp->to_app;
    for my $env ({}, { 'psgi.streaming' => 1 }) {
        my $how = %$env ? 'psgi.streaming' : 'a plain server';
        my $r = $app->({ REQUEST_METHOD => 'HEAD', PATH_INFO => '/events', %$env });
        is(ref $r, 'ARRAY', "HEAD on an sse route ($how) is a plain response");
        is($r->[0], 200, '...a 200');
        is({ @{ $r->[1] } }->{'Content-Type'}, 'text/event-stream',
            '...with the stream\'s headers');
        is(join('', @{ $r->[2] }), '', '...and no body');

        $r = $app->({ REQUEST_METHOD => 'HEAD', PATH_INFO => '/csv', %$env });
        is(ref $r, 'ARRAY', "HEAD on a \$c->stream route ($how) is a plain response");
        is($r->[0], 201, '...with the status it would have had');
        my %h = @{ $r->[1] };
        is($h{'Content-Type'}, 'text/csv', '...its content type');
        is($h{'X-Rows'}, 3, '...its headers');
        is(join('', @{ $r->[2] }), '', '...and no body');
    }
    is($ran, 0, 'no handler ran for any of them');
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
        # 24 MB at a client that reads none of it. Past the buffer limit the
        # stream is closed, which is what this reports; with no limit it
        # would hold all of it for as long as the client stayed.
        our $FLOOD = 'idle';
        sse '/flood' => sub {
            my ($c, $s) = @_;
            $FLOOD = 'open';
            $s->on(close => sub { $FLOOD = 'closed' });
            my $chunk = 'x' x 1_000_000;
            for (1 .. 24) { last unless $s->is_open; $s->send($chunk) }
            $FLOOD = 'held' if $s->is_open;
        }, { heartbeat => 0 };
        get '/flooded' => sub { $_[0]->text($LApp::FLOOD) };
        get '/fast'   => sub { $_[0]->text('fast') };
        get '/closed' => sub { $_[0]->text($LApp::CLOSED) };
        # which event backend this box picked, so a failure names it: the
        # detach path is the same code everywhere but the loop under it is not
        get '/backend' => sub {
            my $s = Hyperman->stats;
            $_[0]->text($s ? ($s->{backend} || '?') : '?');
        };
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
    # undef: nothing accepted the connection at all. '': it was accepted and
    # answered nothing. The two say different things about the worker, so they
    # are not both reported as the empty string.
    my $plain = sub {
        my ($p) = @_;
        my $s = IO::Socket::INET->new(PeerAddr => $host) or return undef;
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

    # asked while the worker is known good, and only reported if the next
    # assertion fails
    my $backend = $plain->('/backend');

    # Drop the client; the worker should fire on(close). Polled rather than
    # slept on: how long the loop takes to notice is a property of the box,
    # and a fixed wait either fails a loaded one or slows every other.
    close $es;
    my $closed;
    for (1 .. 40) {
        Time::HiRes::sleep(0.1);
        $closed = $plain->('/closed');
        last if defined $closed && $closed =~ /\A[1-9]/;
    }
    ok(defined $closed && $closed =~ /\A\d+\z/ && $closed >= 1,
       'dropping the client fired on(close) in the worker')
        or diag sprintf
            "/closed said %s after 4s; the worker is %s; backend %s\n"
          . "(nothing accepted = the process is gone; accepted-no-answer = "
          . "its loop stopped serving)",
            !defined $closed         ? 'nothing accepted the connection'
          : !length $closed          ? 'accepted the connection and answered nothing'
          :                            "'$closed'",
            (waitpid($pid, POSIX::WNOHANG()) == 0 ? 'still running' : 'gone'),
            (defined $backend && length $backend ? $backend : '(unknown)');

    {   # a client that opens a stream and never reads
        my $fs = IO::Socket::INET->new(PeerAddr => $host) or die "connect: $!";
        $fs->autoflush(1);
        syswrite $fs, "GET /flood HTTP/1.1\r\nHost: x\r\n\r\n";
        my $state;
        for (1 .. 40) {
            Time::HiRes::sleep(0.1);
            $state = $plain->('/flooded');
            last if defined $state && $state =~ /\A(?:closed|held)\z/;
        }
        is($state, 'closed',
           'a stream whose client reads nothing is closed at the default '
         . 'buffer limit, not held without one');
        close $fs;
    }

    kill 9, $pid; waitpid $pid, 0;
}

done_testing;
