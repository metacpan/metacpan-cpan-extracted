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

# $c->stream: a streamed response for an ordinary route. The blocking and
# psgi.streaming transports run in-process; the detach transport runs against
# a real Hyperman worker (the t/1020-sse.t harness) and proves the drain
# future is real backpressure - the worker serves other requests while a
# stream waits for its client to read.

use Punk::Stream;

# split a raw chunked body into (payload, saw_terminal_chunk)
sub dechunk {
    my ($b) = @_;
    my $out = '';
    while ($b =~ s/\A([0-9a-fA-F]+)\r\n//) {
        my $n = hex $1;
        return ($out, 1) if $n == 0;
        $out .= substr($b, 0, $n);
        substr($b, 0, $n + 2) = '';       # the chunk and its CRLF
    }
    return ($out, 0);
}

# ---- blocking transport: chunked framing, drain, close, late writes ----------
{
    package BApp;
    use Punk;
    our $AFTER_CLOSE = 'unset';
    get '/csv' => sub {
        my $c = shift;
        $c->stream('text/csv', { blocking => 1 }, sub {
            my ($c2, $w) = @_;
            $w->write("a,b\n");
            my ($ok) = $c2->await($w->drain);
            die "drain said $ok\n" unless $ok;
            $w->write("1,2\n");
            $w->close;
            $w->write("late\n");                       # ignored: closed
            ($AFTER_CLOSE) = $c2->await($w->drain);    # settled 0: closed
            die "still open\n" if $w->is_open;
        });
    };
    package main;

    my $app = BApp->to_app;
    socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $r = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/csv',
                     SERVER_PROTOCOL => 'HTTP/1.1', 'psgix.io' => $theirs });
    close $theirs;
    is($r->[0], 200, 'blocking stream returns a 200 sentinel triplet');

    my $raw = '';
    eval { local $SIG{ALRM} = sub { die "to\n" }; alarm 2;
           while (sysread $ours, my $c, 4096) { $raw .= $c } alarm 0 };
    my ($head, $body) = split /\r\n\r\n/, $raw, 2;
    like($head, qr{^HTTP/1\.1 200 OK\r\n}, 'the HTTP status line');
    like($head, qr{Content-Type: text/csv\r\n}, 'the declared content type');
    like($head, qr{Transfer-Encoding: chunked\r\n}, 'chunked on HTTP/1.1');
    like($head, qr{Connection: close\r\n}, 'and close-delimited');

    my ($payload, $terminal) = dechunk($body);
    is($payload, "a,b\n1,2\n", 'the body reassembles byte-exact');
    ok($terminal, 'a clean close sends the terminal chunk');
    unlike($payload, qr/late/, 'a write after close is ignored');
    is($BApp::AFTER_CLOSE, 0, 'drain after close settles with 0');
}

# ---- HTTP/1.0: no chunked framing, close delimits ----------------------------
{
    package OldApp;
    use Punk;
    get '/x' => sub {
        $_[0]->stream('text/plain', { blocking => 1 },
                      sub { $_[1]->write('one')->write('two') });
    };
    package main;

    my $app = OldApp->to_app;
    socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/x',
             SERVER_PROTOCOL => 'HTTP/1.0', 'psgix.io' => $theirs });
    close $theirs;
    my $raw = '';
    eval { local $SIG{ALRM} = sub { die "to\n" }; alarm 2;
           while (sysread $ours, my $c, 4096) { $raw .= $c } alarm 0 };
    my ($head, $body) = split /\r\n\r\n/, $raw, 2;
    unlike($head, qr{Transfer-Encoding}, 'no chunked framing for HTTP/1.0');
    is($body, 'onetwo', 'the raw body, close-delimited');
}

# ---- the multiplexed versions: also no chunked framing -----------------------
#
# Chunked transfer coding is HTTP/1.1's and only HTTP/1.1's. HTTP/1.0 has no
# such coding and HTTP/2 and HTTP/3 forbid the header outright, framing the
# body in the protocol instead. So the test asks whether the protocol IS
# HTTP/1.1, rather than whether it is not HTTP/1.0 - which put a
# Transfer-Encoding on every h2 response, Hyperman spelling its h2 protocol
# "HTTP/2" (six bytes, not "HTTP/2.0") and never matching the exclusion.
#
# A missing SERVER_PROTOCOL is HTTP/1.1, which is what the synthetic
# environments elsewhere in this file rely on.
{
    package MuxApp;
    use Punk;
    get '/x' => sub {
        $_[0]->stream('text/plain', { blocking => 1 },
                      sub { $_[1]->write('one')->write('two') });
    };
    package main;
}
my $muxapp = MuxApp->to_app;

for my $case ([ 'HTTP/2', 'h2' ], [ 'HTTP/3', 'h3' ], [ undef, 'no SERVER_PROTOCOL' ]) {
    my ($proto, $label) = @$case;

    socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    $muxapp->({ REQUEST_METHOD => 'GET', PATH_INFO => '/x',
                (defined $proto ? (SERVER_PROTOCOL => $proto) : ()),
                'psgix.io' => $theirs });
    close $theirs;
    my $raw = '';
    eval { local $SIG{ALRM} = sub { die "to\n" }; alarm 2;
           while (sysread $ours, my $c, 4096) { $raw .= $c } alarm 0 };
    my ($head, $body) = split /\r\n\r\n/, $raw, 2;
    if (defined $proto) {
        unlike($head, qr{Transfer-Encoding}, "no chunked framing for $label");
        is($body, 'onetwo', "the raw body for $label, framed by the transport");
    }
    else {
        like($head, qr{Transfer-Encoding: chunked\r\n},
             'chunked framing when SERVER_PROTOCOL is absent');
        my ($payload) = dechunk($body);
        is($payload, 'onetwo', '...and the body still reassembles');
    }
}

# ---- a die mid-stream is visible truncation ----------------------------------
{
    package DieApp;
    use Punk;
    get '/die' => sub {
        $_[0]->stream('text/csv', { blocking => 1 }, sub {
            $_[1]->write("head\n");
            die "boom at row 3\n";
        });
    };
    package main;

    my $app = DieApp->to_app;
    socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my @warned;
    {
        local $SIG{__WARN__} = sub { push @warned, $_[0] };
        $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/die',
                 SERVER_PROTOCOL => 'HTTP/1.1', 'psgix.io' => $theirs,
                 'psgix.request_id' => 'req-42' });
    }
    close $theirs;
    my $raw = '';
    eval { local $SIG{ALRM} = sub { die "to\n" }; alarm 2;
           while (sysread $ours, my $c, 4096) { $raw .= $c } alarm 0 };
    my (undef, $body) = split /\r\n\r\n/, $raw, 2;
    my ($payload, $terminal) = dechunk($body);
    is($payload, "head\n", 'what was written before the die arrived');
    ok(!$terminal, 'no terminal chunk: the client sees truncation');
    like($warned[0] || '', qr/handler died \(request req-42\): boom at row 3/,
         'the death is reported with the request id');
}

# ---- psgi.streaming, through the test client ---------------------------------
{
    package SApp;
    use Punk;
    get '/ndjson' => sub {
        $_[0]->stream('application/x-ndjson', sub {
            my ($c, $w) = @_;
            $w->write(qq[{"n":$_}\n]) for 1 .. 3;
        });
    };
    get '/attach' => sub {
        $_[0]->stream('text/csv', {
            status  => 201,
            headers => [ 'Content-Disposition' => 'attachment; filename="r.csv"' ],
        }, sub { $_[1]->write("a\n") });
    };
    package main;

    require Punk::Test;
    my $t = Punk::Test->new('SApp');
    $t->get_ok('/ndjson')
      ->status_is(200)
      ->header_is('Content-Type' => 'application/x-ndjson')
      ->header_is('X-Accel-Buffering' => 'no')
      ->content_is(qq[{"n":1}\n{"n":2}\n{"n":3}\n]);
    $t->get_ok('/attach')
      ->status_is(201)
      ->header_is('Content-Disposition' => 'attachment; filename="r.csv"');
}

# ---- the call-time croaks, and the 501 fallback -------------------------------
{
    package CroakApp;
    use Punk;
    get '/unknown' => sub { $_[0]->stream('t/p', { nope => 1 },   sub { }) };
    get '/oddhdr'  => sub { $_[0]->stream('t/p', { headers => ['K'] }, sub { }) };
    get '/inject'  => sub { $_[0]->stream('t/p',
                          { headers => [ K => "v\r\nEvil: 1" ] }, sub { }) };
    get '/status'  => sub { $_[0]->stream('t/p', { status => 42 }, sub { }) };
    get '/nocode'  => sub { $_[0]->stream('t/p', 'not a coderef') };
    get '/noct'    => sub { $_[0]->stream("t/p\r\n", sub { }) };
    get '/ok'      => sub { $_[0]->stream('t/p', sub { $_[1]->write('x') }) };
    package main;

    require Punk::Test;
    my $app = CroakApp->to_app;
    my $t = Punk::Test->new($app);
    $t->get_ok('/unknown')->status_is(500)
      ->content_like(qr/unknown stream option 'nope'/);
    $t->get_ok('/oddhdr')->status_is(500)
      ->content_like(qr/arrayref of pairs/);
    $t->get_ok('/inject')->status_is(500)
      ->content_like(qr/control byte/);
    $t->get_ok('/status')->status_is(500)
      ->content_like(qr/not an HTTP status/);
    $t->get_ok('/nocode')->status_is(500)
      ->content_like(qr/needs a coderef/);
    $t->get_ok('/noct')->status_is(500)
      ->content_like(qr/control byte/);

    # no detach seam, no psgi.streaming, no blocking => 1: an honest 501
    my $r = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/ok',
                     SERVER_PROTOCOL => 'HTTP/1.1' });
    is($r->[0], 501, 'no transport at all answers 501');
    like($r->[2][0], qr/cannot stream a response/, 'naming what it needs');
}

# ---- the write path does not retain the body (blocking, forked reader) -------
SKIP: {
    skip 'no ps -o rss on this platform', 2 if $^O eq 'MSWin32';
    my $rss = sub {
        my $out = `ps -o rss= -p $$` // '';
        $out =~ /(\d+)/ ? $1 : undef;
    };
    skip 'ps -o rss unusable', 2 unless defined $rss->();

    package RssApp;
    use Punk;
    get '/big' => sub {
        my $c = shift;
        $c->stream('application/octet-stream', { blocking => 1 }, sub {
            my ($c2, $w) = @_;
            my $chunk = 'x' x (1024 * 1024);
            $w->write($chunk) for 1 .. 64;             # 64MB total
        });
    };
    package main;

    socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $pid = fork // die "fork: $!";
    if (!$pid) {                                       # the reading client
        close $theirs;
        my $got = 0;
        $got += length $_ while sysread($ours, $_, 1 << 20);
        POSIX::_exit($got >= 64 * 1024 * 1024 ? 0 : 1);
    }
    close $ours;
    my $before = $rss->();
    my $r = RssApp->to_app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/big',
                               SERVER_PROTOCOL => 'HTTP/1.1',
                               'psgix.io' => $theirs });
    close $theirs;
    my $after = $rss->();
    waitpid $pid, 0;
    is($? >> 8, 0, 'the client received all 64MB (and the framing)');
    my $grew = ($after - $before) / 1024;              # KB -> MB
    ok($grew < 32, sprintf 'streaming 64MB grew RSS %.1fMB (< 32MB)', $grew)
        or diag "before ${before}KB after ${after}KB";
}

# ---- detach transport, on a real Hyperman worker -----------------------------
SKIP: {
    eval { require Hyperman; require Punk::WebSocket; 1 }
        or skip 'Hyperman required for the loop tests', 1;
    require IO::Socket::INET;
    skip 'Hyperman 0.11+ (a live loop) required', 1
        unless Punk::WebSocket::_hm_available();

    my $chunkbody = 'x' x 16384;
    my $port = 26700 + ($$ % 300);
    my $host = "127.0.0.1:$port";
    my $pid  = fork // die "fork: $!";
    if (!$pid) {
        close STDERR;
        package LApp;
        use Punk;
        our $ABORT = 0;
        get '/export' => sub {
            my $c = shift;
            $c->stream('text/plain', sub {
                my ($c2, $w) = @_;
                for my $i (1 .. 256) {                 # ~4MB: past any socket buffer
                    $w->write("xxxxxxxx" x 2048);      # 16KB
                    $w->write(":$i\n");
                    my ($ok) = $c2->await($w->drain);
                    if (!$ok) { $LApp::ABORT++; return }
                }
            });
        };
        # the dropped-client route has no end: a fixed-size export can be
        # swallowed whole by the kernel before the client's reset arrives
        # (Linux autotunes a loopback send buffer up to 4MB), and a handler
        # that finished never sees its drain settle 0
        get '/forever' => sub {
            my $c = shift;
            $c->stream('text/plain', sub {
                my ($c2, $w) = @_;
                for (1 .. 65536) {                     # 1GB: no buffer holds it
                    $w->write("xxxxxxxx" x 2048);      # 16KB
                    my ($ok) = $c2->await($w->drain);
                    if (!$ok) { $LApp::ABORT++; return }
                }
            });
        };
        get '/fast'  => sub { $_[0]->text('fast') };
        get '/abort' => sub { $_[0]->text($LApp::ABORT) };
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
        my $s = IO::Socket::INET->new(PeerAddr => $host) or return undef;
        $s->autoflush(1);
        syswrite $s, "GET $p HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n";
        my $b = '';
        eval { local $SIG{ALRM} = sub { die "to\n" }; alarm 3;
               while (sysread $s, my $c, 4096) { $b .= $c } alarm 0 };
        $b =~ s/.*\r\n\r\n//s;
        return $b;
    };

    # open the export and read only its first bytes, so the stream is parked
    # on a pending drain future while we ask the same worker for /fast
    my $es = IO::Socket::INET->new(PeerAddr => $host) or die "connect: $!";
    $es->autoflush(1);
    syswrite $es, "GET /export HTTP/1.1\r\nHost: x\r\n\r\n";
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "to\n" }; alarm 3;
           sysread $es, $buf, 4096; alarm 0 };
    like($buf, qr{^HTTP/1\.1 200 OK}, 'the stream opens with a 200');
    like($buf, qr{Transfer-Encoding: chunked}, 'chunked over the loop');

    my $t0 = Time::HiRes::time();
    is($plain->('/fast'), 'fast',
       'a plain request is served while the export waits on drain');
    ok(Time::HiRes::time() - $t0 < 0.5, 'and served promptly (worker not pinned)');

    # now read the whole thing and check every byte arrived, in order
    eval { local $SIG{ALRM} = sub { die "to\n" }; alarm 20;
           while (sysread $es, my $c, 1 << 20) { $buf .= $c } alarm 0 };
    close $es;
    my (undef, $body) = split /\r\n\r\n/, $buf, 2;
    my ($payload, $terminal) = dechunk($body);
    my $expect = '';
    $expect .= ("xxxxxxxx" x 2048) . ":$_\n" for 1 .. 256;
    ok($terminal, 'the export ends with the terminal chunk');
    is(length $payload, length $expect, 'every byte arrived');
    is(substr($payload, -20), substr($expect, -20), 'in order, to the end');

    # drop a client mid-stream; the worker's drain settles 0 and the handler
    # bails out. Polled, not slept on (the loop notices when it notices).
    my $es2 = IO::Socket::INET->new(PeerAddr => $host) or die "connect: $!";
    $es2->autoflush(1);
    syswrite $es2, "GET /forever HTTP/1.1\r\nHost: x\r\n\r\n";
    eval { local $SIG{ALRM} = sub { die "to\n" }; alarm 3;
           sysread $es2, my $first, 4096; alarm 0 };
    close $es2;
    my $abort;
    for (1 .. 40) {
        Time::HiRes::sleep(0.1);
        $abort = $plain->('/abort');
        last if defined $abort && $abort =~ /\A[1-9]/;
    }
    ok(defined $abort && $abort =~ /\A\d+\z/ && $abort >= 1,
       'dropping the client settles drain with 0 and the handler bails')
        or diag 'abort counter said ' . (defined $abort ? "'$abort'" : 'undef');

    kill 9, $pid; waitpid $pid, 0;
}

done_testing;
