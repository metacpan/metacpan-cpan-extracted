#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use File::Spec ();
use File::Temp ();
use POSIX ();

# SSE and $c->stream over a multiplexed transport, through Hyperman's ABI v6
# stream handle.
#
# Both route kinds used to be built on hm_detach, which hands over a file
# descriptor - and which refuses HTTP/2 (a stream is one of many on a shared
# connection, so no fd means "this stream") and TLS (the session state belongs
# to the server). Those refusals are right, so the fix is a different seam
# rather than a wider detach: stream_open takes a ticket and gives back a
# handle, and the transport branch lives behind it.
#
# What that means at the wire is asserted here rather than in-process, because
# the claim is about bytes Hyperman puts on a socket. HTTP/1.1 in clear still
# takes detach and must be byte-identical; t/1020-sse.t and t/1040-stream.t
# hold the rest of that ground.
#
# A refusal is a response plus a close while a client may still be writing.
$SIG{PIPE} = 'IGNORE';

our $ABORTED = 0;
our $PRESS   = File::Spec->catfile(File::Temp::tempdir(CLEANUP => 1), 'press');

plan skip_all => 'Hyperman required' unless eval { require Hyperman; 1 };
plan skip_all => 'Hyperman built without nghttp2' unless Hyperman->has_http2;
my $curl = `which curl 2>/dev/null`;
chomp $curl;
plan skip_all => 'curl not found' unless $curl;
plan skip_all => 'curl lacks HTTP/2'
    unless `curl --version 2>/dev/null` =~ /\bHTTP2\b/;
require IO::Socket::INET;

{
    package HApp;
    use Punk;

    sse '/events' => sub {
        my ($c, $s) = @_;
        $s->send('one');
        $s->send('two');
        $s->close;
    };

    # An event, and then the stream stays open - which is what an SSE stream
    # normally does. This is the case a writer that buffers to close cannot
    # serve at all: the bytes sit in the server until an end that never comes.
    sse '/drip' => sub { $_[1]->send('drip') };

    # opened and left open: whatever kills it next - the client hanging up,
    # a stream reset - is what the close callback is there to catch
    sse '/hold' => sub {
        my ($c, $s) = @_;
        $s->on(close => sub { $main::ABORTED++ });
        $s->send('holding');
    };

    get '/aborted' => sub { $_[0]->text("aborted:$main::ABORTED") };

    get '/csv' => sub {
        $_[0]->stream('text/csv', sub {
            my ($c, $w) = @_;
            $w->write("a,b\n");
            $w->write("1,2\n");
            $w->close;
        });
    };

    # A producer that fails half way. What the client must NOT get is a
    # clean end: the body has no declared length, so ending normally is the
    # only claim there is that it is whole, and "head\n" is not.
    get '/dies' => sub {
        $_[0]->stream('text/csv', sub {
            $_[1]->write("head\n");
            die "boom at row 3\n";
        });
    };

    # More than the connection will take at once, then ask to be told when
    # it has gone. What is recorded is whether each drain was pending when it
    # was handed back: on this transport it used to come back settled every
    # time, so the loop below never waited and the whole body sat in the
    # server's buffer for a slow client.
    get '/big' => sub {
        $_[0]->stream('application/octet-stream', sub {
            my ($c, $w) = @_;
            my $states = '';
            if (my $n = $c->param('n')) {       # a plain body of n bytes
                $w->write('x' x $n);
                $w->write("\n-\n");
                return $w->close;
            }
            for (1 .. 3) {
                $w->write('x' x 2_000_000);
                my $f = $w->drain;
                $states .= $f->is_ready ? 'r' : 'p';
                $f->get;
            }
            $w->write("\n$states\n");
            $w->close;
        });
    };

    # One write, far more than a socket holds for a client that is not
    # reading, and what drain said straight after it goes to a file: that
    # client never reads a body to find it in.
    get '/press' => sub {
        $_[0]->stream('application/octet-stream', sub {
            my ($c, $w) = @_;
            $w->write('x' x 8_000_000);
            my $f = $w->drain;
            if (open my $fh, '>', "$main::PRESS.tmp") {
                print $fh $f->is_ready ? 'r' : 'p';
                close $fh;
                rename "$main::PRESS.tmp", $main::PRESS;
            }
            $f->get;
            $w->close;
        });
    };

    get '/attach' => sub {
        $_[0]->stream('text/csv', {
            status  => 201,
            headers => [ 'Content-Disposition' => 'attachment; filename="r.csv"' ],
        }, sub { $_[1]->write("a\n") });
    };

    package main;
}

my $app = HApp->to_app;

# An ephemeral port the kernel just handed out rather than one derived from
# $$: two runs whose pids agree modulo the span pick the same number, and the
# second then talks to the first one's server.
sub free_port {
    my $s = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
                                  Proto => 'tcp', Listen => 5, ReuseAddr => 1)
        or return undef;
    my $p = $s->sockport;
    close $s;
    return $p;
}

# Nothing in a forked child may hold the harness's TAP pipe: the harness reads
# until EOF, so one surviving server hangs `make test` after every assertion
# has already passed. Test::Builder dups the pipe into its own handles when it
# loads, so those are closed too, and the alarm is the backstop for a child
# nobody reaps.
sub serve {
    my (%o) = @_;
    my $pid = fork;
    return undef unless defined $pid;
    if (!$pid) {
        open STDOUT, '>', File::Spec->devnull;
        open STDERR, '>', File::Spec->devnull;
        if (my $tb = eval { Test::Builder->new }) {
            for my $h (eval { $tb->output }, eval { $tb->failure_output },
                       eval { $tb->todo_output }) {
                close $h if defined $h;
            }
        }
        alarm 60;
        Hyperman->run(app => $app, host => '127.0.0.1', workers => 1,
                      http2 => 1, %o);
        POSIX::_exit(0);
    }
    for (1 .. 60) {
        my $c = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$o{port}");
        last if $c;
        select undef, undef, undef, 0.1;
    }
    return $pid;
}

# A TLS client that asks for a path and then never reads the answer. The
# request goes in on a pipe that stays open, so s_client does not see the end
# of its input and leave; the response comes out on one nobody reads.
sub stalled_client {
    my ($port, $path) = @_;
    pipe(my $ir, my $iw) or return;
    pipe(my $or, my $ow) or return;
    my $pid = fork;
    return unless defined $pid;
    if (!$pid) {
        open STDIN,  '<&', $ir;
        open STDOUT, '>&', $ow;
        open STDERR, '>', File::Spec->devnull;
        close $_ for $iw, $or;
        exec('openssl', 's_client', '-quiet', '-connect', "127.0.0.1:$port")
            or POSIX::_exit(1);
    }
    close $_ for $ir, $ow;
    syswrite $iw, "GET $path HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n";
    return ($pid, $iw, $or);
}

# Headers and body, split. -i puts the response head in the body stream, which
# is the only way to see it and the payload from one request.
sub fetch {
    my ($url, @flags) = @_;
    my $out = `curl -si --max-time 10 @flags '$url' 2>/dev/null`;
    my ($head, $body) = split /\r?\n\r?\n/, ($out // ''), 2;
    return (defined $head ? $head : '', defined $body ? $body : '');
}

# ---- HTTP/2 in clear ---------------------------------------------------------

{
    my $port = free_port();
    plan skip_all => 'no free loopback port' unless $port;
    my $pid = serve(port => $port);
    plan skip_all => "fork: $!" unless $pid;
    my $base = "http://127.0.0.1:$port";
    my $h2   = '--http2-prior-knowledge';

    {
        my ($head, $body) = fetch("$base/events", $h2);
        like($head, qr{^HTTP/2 200}, 'SSE answers 200 over h2');
        like($head, qr{content-type: text/event-stream},
             '...as an event stream');
        like($head, qr{cache-control: no-cache}, '...uncached');
        is($body, "data: one\n\ndata: two\n\n",
           '...and the events arrive, which is the whole claim');
    }

    {   # The decisive one for SSE. Answering /events proves little on its own:
        # the psgi.streaming writer this used to fall through to buffers the
        # whole body and sends it at close, so a stream that closes looks the
        # same either way. A stream that does NOT close is the real shape of
        # SSE, and under a buffering writer it delivers nothing, ever. The
        # client gives up after two seconds and prints what it got by then.
        my $out = `curl -s --max-time 2 $h2 '$base/drip' 2>/dev/null`;
        like($out, qr/^data: drip$/m,
             'an SSE stream that never closes still delivers as it produces');
    }

    {
        my ($head, $body) = fetch("$base/csv", $h2);
        like($head, qr{^HTTP/2 200}, '$c->stream answers 200 over h2');
        like($head, qr{content-type: text/csv}, '...with the declared type');
        is($body, "a,b\n1,2\n", '...and the body is byte-exact, unframed');
    }

  SKIP: {
        # Hyperman up to 0.58 ends an h2 stream on the first DATA frame sent
        # after the close, so a body is cut wherever the close happened to
        # land: at 16384 bytes when nothing had gone out yet, later when the
        # socket took some frames first. A small probe therefore says nothing
        # about a large body, and the body itself is the only probe there is.
        # That is the server's to fix; this checks that the handler's own
        # loop - write, drain, wait - ends with the whole body on a server
        # that sends one. Whether drain is ever PENDING over h2 is the
        # server's too, and is asserted below on a Hyperman that reports
        # it.
        my $out = `curl -s --max-time 20 $h2 '$base/big' 2>/dev/null`;
        skip 'this Hyperman truncates an HTTP/2 stream body', 1
            if length($out) != 6_000_000 + 5
            && !eval { Hyperman->VERSION('0.59'); 1 };
        is(length $out, 6_000_000 + 5,
           'a write, drain, wait loop delivers the whole body over h2');
    }

    {   # the options survive the header list the same way they survive
        # pst_head's byte string
        my ($head, $body) = fetch("$base/attach", $h2);
        like($head, qr{^HTTP/2 201}, 'a stream status option reaches the wire');
        like($head, qr{content-disposition: attachment; filename="r\.csv"},
             '...and so do the caller\'s own headers');
    }

    {   # A die mid-stream, which on the chunked transports withholds the
        # terminal chunk. The stream handle has its own way of saying it -
        # RST_STREAM on h2 - and curl reports the transfer as failed. What
        # would be wrong is exit 0 with a short body that looks complete.
        my $out = `curl -s -o /dev/null -w '%{exit_code}' --max-time 10 $h2 '$base/dies' 2>/dev/null`;
        isnt($out, '0',
             'a die mid-stream over h2 fails the transfer, not a short success');
    }

    # ---- what must NOT be there ----------------------------------------------
    #
    # Both headers are hop-by-hop and forbidden in HTTP/2. Transfer-Encoding is
    # the SERVER_PROTOCOL fix showing up at the wire - the old test
    # chunk-framed anything that was not literally HTTP/1.0, and Hyperman
    # spells its h2 protocol "HTTP/2", six bytes and not "HTTP/2.0".
    for my $path (qw(/events /csv)) {
        my ($head) = fetch("$base$path", $h2);
        unlike($head, qr{^transfer-encoding}mi, "no Transfer-Encoding on h2 $path");
        unlike($head, qr{^connection:}mi,       "no Connection on h2 $path");
    }

    # ---- HTTP/1.1 through the same server, unchanged -------------------------
    #
    # The point of asserting it here as well as in t/1040-stream.t: this is the
    # server that now has a second transport available, and it must still not
    # take it. Chunk framing and Connection: close are what detach writes.
    {
        my ($head, $body) = fetch("$base/csv", '--http1.1');
        like($head, qr{^HTTP/1\.1 200 OK}, 'HTTP/1.1 still gets the status line');
        like($head, qr{^Transfer-Encoding: chunked}mi,
             '...still chunk-framed, so detach still serves it');
        like($head, qr{^Connection: close}mi, '...and still close-delimited');
        is($body, "a,b\n1,2\n", '...with the same body');
    }

    {
        my ($head, $body) = fetch("$base/events", '--http1.1');
        like($head, qr{^HTTP/1\.1 200 OK}, 'HTTP/1.1 SSE is unchanged too');
        like($head, qr{^Connection: keep-alive}mi,
             '...including the header h2 must not have');
        is($body, "data: one\n\ndata: two\n\n", '...and the same events');
    }

    # ---- the abort path ------------------------------------------------------
    #
    # A stream left open, then a client that goes away. The producer has to
    # hear about it: on HTTP/1 a dead stream IS a dead connection and detach
    # could infer it, but on a multiplexed transport it is not, which is why
    # stream_on_abort exists and why $s->on(close) has to be wired to it.
    #
    # The counter is read back through a LATER request rather than asserted in
    # the client, because it lives in the worker - the shape t/41-stream-abi.t
    # uses in Hyperman for the same reason. workers => 1 is what makes the
    # second request land in the process that saw the first.
    {
        my ($before) = fetch("$base/aborted", $h2);
        my (undef, $b0) = fetch("$base/aborted", $h2);
        is($b0, 'aborted:0', 'nothing has aborted yet');

        # --max-time cuts the client off while the stream is still open
        system(qq{curl -s --max-time 1 $h2 '$base/hold' >/dev/null 2>&1});

        # Converge rather than sleeping for a guessed interval: a fixed sleep
        # is what fails on a loaded smoker.
        my $got = '';
        for (1 .. 50) {
            (undef, $got) = fetch("$base/aborted", $h2);
            last if $got && $got ne 'aborted:0';
            select undef, undef, undef, 0.1;
        }
        is($got, 'aborted:1',
           'a client that goes away aborts the stream and the handler hears it');
    }

  SKIP: {
        # Backpressure over h2. The limit there is the peer's flow-control
        # window, and what it has not opened waits in the stream's own buffer
        # - which the server did not count until 0.60, so drain was settled
        # at once and the whole body was held. The handler also waits inside
        # the request, which an h2 server can only serve if it reads the
        # connection meanwhile.
        #
        # The client speaks h2 by hand: a preface, an empty SETTINGS and one
        # HEADERS frame, then nothing - no window update, no read. Its
        # window is the default 65,535 bytes against an 8 MB write.
        skip 'Hyperman 0.60 or later reports pressure on an h2 stream', 1
            unless eval { Hyperman->VERSION('0.60'); 1 };
        unlink $PRESS;
        my $sock = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port")
            or skip "connect: $!", 1;
        my $frame = sub {
            my ($type, $flags, $sid, $pay) = @_;
            my $l = length $pay;
            return pack('CCCCCN', ($l >> 16) & 0xff, ($l >> 8) & 0xff,
                        $l & 0xff, $type, $flags, $sid) . $pay;
        };
        my $lit = sub {          # an HPACK literal, never indexed
            my ($n, $v) = @_;
            return "\x00" . chr(length $n) . $n . chr(length $v) . $v;
        };
        syswrite $sock, "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"
                      . $frame->(0x4, 0, 0, '')
                      . $frame->(0x1, 0x5, 1,
                            $lit->(':method', 'GET') . $lit->(':scheme', 'http')
                          . $lit->(':path', '/press')
                          . $lit->(':authority', "127.0.0.1:$port"));
        my $state = '';
        for (1 .. 100) {
            if (open my $fh, '<', $PRESS) {
                $state = <$fh> // '';
                close $fh;
                last;
            }
            select undef, undef, undef, 0.1;
        }
        is($state, 'p',
           'over h2, drain is pending while the stream holds what the '
         . 'client has not made room for');
        close $sock;          # the waiting handler hears the abort and ends
    }

    kill 'TERM', $pid;
    waitpid $pid, 0;
}

# ---- HTTP/1.1 over TLS -------------------------------------------------------
#
# The other case detach refuses, and the reason Punk/example/Chat documented
# terminating TLS in front and speaking plain HTTP/1 to the application. There
# is no fd to hand over because the session state is the server's, so this used
# to be a 503; the stream handle serves it.

SKIP: {
    my $n = 6;
    skip 'OpenSSL support not built', $n unless Hyperman->has_tls;
    my $openssl = `which openssl 2>/dev/null`;
    chomp $openssl;
    skip 'openssl CLI not found', $n unless $openssl;

    my $dir  = File::Temp::tempdir(CLEANUP => 1);
    my $cert = "$dir/cert.pem";
    my $key  = "$dir/key.pem";
    system(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout "$key" }
         . qq{-out "$cert" -days 1 -subj "/CN=localhost" >/dev/null 2>&1});
    skip 'could not create a self-signed cert', $n
        unless -s $cert && -s $key;

    my $port = free_port();
    skip 'no free loopback port', $n unless $port;
    my $pid = serve(port => $port, tls_cert => $cert, tls_key => $key);
    skip "fork: $!", $n unless $pid;
    my $base = "https://127.0.0.1:$port";

    {
        my ($head, $body) = fetch("$base/csv", '-k --http1.1');
        like($head, qr{^HTTP/1\.1 200}, '$c->stream is served over TLS');
        is($body, "a,b\n1,2\n", '...and the body arrives, where it used to 503');
    }

    {
        my ($head, $body) = fetch("$base/events", '-k --http1.1');
        like($head, qr{^HTTP/1\.1 200}, 'SSE is served over TLS');
        is($body, "data: one\n\ndata: two\n\n", '...and the events arrive');
    }

    {
        my $out = `curl -sk --http1.1 --max-time 20 '$base/big' 2>/dev/null`;
        is(length $out, 6_000_000 + 5,
           'a body larger than the connection takes at once arrives whole');
    }

    {   # Backpressure on the stream handle. A client that reads slowly is
        # not enough to ask the question: how much the kernel takes off the
        # server's hands before drain is called is the kernel's business, and
        # on some it is the whole write. This client does not read at all -
        # s_client stops taking from the socket once the pipe it prints to is
        # full, and nothing empties that pipe - so the server is holding
        # output when drain is asked for, and drain has to say so, or the
        # loop in the handler never waits and the server buffers the lot.
        my ($pid2, $in, $out) = stalled_client($port, '/press');
        my $state = '';
        for (1 .. 100) {
            if (open my $fh, '<', $PRESS) {
                $state = <$fh> // '';
                close $fh;
                last;
            }
            select undef, undef, undef, 0.1;
        }
        is($state, 'p',
           'drain is pending while the server holds output for a client '
         . 'that is not reading');
        if ($pid2) {
            kill 'KILL', $pid2;
            waitpid $pid2, 0;
        }
    }

    kill 'TERM', $pid;
    waitpid $pid, 0;
}

done_testing;
