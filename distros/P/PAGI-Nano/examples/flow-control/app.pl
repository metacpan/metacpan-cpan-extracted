use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use PAGI::Nano;

# Ports PAGI's 13-flow-control to PAGI::Nano.
# A high-frequency SSE feed that *conflates* under backpressure: when the client
# falls behind (the transport's buffered bytes exceed the high-water mark) the
# server skips stale readings and sends only the freshest, so a slow client never
# accumulates a backlog. $c->buffered_amount / $c->high_water_mark expose the
# transport's write buffer.
#
#     pagi-server app.pl
#     curl -N http://127.0.0.1:5000/feed

my $app = app {
    sse '/feed' => async sub ($c) {
        my $s = $c->sse;
        my $hwm = $c->high_water_mark // 65536;

        my $latest;
        for my $i (1 .. 10) {
            $latest = "reading $i";
            my $buffered = $c->buffered_amount // 0;
            if ($buffered < $hwm) {
                await $s->send($latest);          # client keeping up: send it
            }
            # else: client behind -> drop this reading (conflate to freshest)
        }
        await $s->send("final: $latest");         # always deliver the freshest
        await $s->close;
    };
};

$app;
