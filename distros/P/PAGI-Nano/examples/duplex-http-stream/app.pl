use v5.40;
use experimental 'signatures';
use Future;
use Future::AsyncAwait;
use Future::IO;
use PAGI::Nano;

# Full-duplex over a single HTTP request: read the streaming request body while
# concurrently streaming the response. This is the HTTP-streaming analog of
# examples/bidirectional-websocket — two branches raced with wait_any, one
# echoing client input, one pushing server ticks unsolicited.
#
# Caveats (this is why WebSocket exists): no message framing (it's a byte stream
# both ways), browsers can't do full-duplex on a single fetch, and HTTP/1.1
# proxies may buffer the request before forwarding. It is a fine fit for
# non-browser / service-to-service / HTTP-2 clients.
#
#     pagi-server app.pl
#
#     # Plain POST sends NO request body, so there is nothing to echo; the
#     # connection drives the stream, so ticks keep coming until you stop reading:
#     curl -N -XPOST --max-time 4 http://127.0.0.1:5000/duplex
#
#     # To actually send a body and see echoes, stream stdin as the body with
#     # `-T -` (so you get echo: lines interleaved with ticks):
#     ( printf 'hello\n'; sleep 1; printf 'world\n'; sleep 2 ) \
#         | curl -N -T - -XPOST -H 'Transfer-Encoding: chunked' http://127.0.0.1:5000/duplex
#
#     # Note: typing into `curl -T -` interactively lags by one line — curl holds
#     # the line you just typed in its upload buffer until its next read. That is
#     # a curl artifact, not the server: the server echoes each chunk within ~40ms
#     # of receiving it. For a real-time wire proof use the raw-socket probe, which
#     # flushes each chunk immediately:
#     perl probe.pl 5000

my $app = app {
    post '/duplex' => async sub ($c) {
        my $in = $c->req->body_stream;
        $c->response->stream(async sub ($w) {
            # Echo request-body chunks as they arrive, concurrently. This branch
            # ends when the client finishes its body — but that must NOT end the
            # stream: the client can stop sending and keep receiving. So it runs
            # alongside the ticker, it does not drive termination.
            my $echoer = (async sub {
                while (defined(my $chunk = await $in->next_chunk)) {
                    next unless length $chunk;
                    await $w->write("echo: $chunk\n");
                }
            })->();

            # The stream lives as long as the client stays connected, pushing a
            # tick a second. A ?ticks=N cap bounds the run for demos and for
            # in-process tests (PAGI::Test::Client models a client that stays
            # connected and cannot disconnect mid-response, so an unbounded
            # connection-driven stream would never complete there). Without the
            # cap, the connection drives termination — see probe.pl against
            # pagi-server for the real full-duplex run.
            my $max = $c->req->query_param('ticks');
            my $n = 0;
            while (!$c->is_disconnected && (!defined $max || $n < $max)) {
                await $w->write('tick ' . (++$n) . "\n");
                await Future::IO->sleep(1);
            }

            $echoer->cancel unless $echoer->is_ready;
            await $w->close;
        });
    };
};

$app;
