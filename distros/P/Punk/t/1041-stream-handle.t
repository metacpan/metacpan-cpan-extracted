#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
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
    my $n = 4;
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

    kill 'TERM', $pid;
    waitpid $pid, 0;
}

done_testing;
