use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use PAGI::Nano;

# Ports PAGI's 05-sse-broadcaster (and PAGI-Tools' sse-dashboard) to PAGI::Nano.
# An imperative SSE handler sends a series of named events with ids (ids let a
# reconnecting client resume via Last-Event-ID). For a long-lived feed you would
# loop with $s->keepalive and a timer; here we send a fixed burst.
#
#     pagi-server app.pl
#     curl -N http://127.0.0.1:5000/events

my $app = app {
    sse '/events' => async sub ($c) {
        my $s = $c->sse;
        for my $i (1 .. 5) {
            await $s->send_event(event => 'tick', id => $i, data => "ping $i");
        }
        await $s->close;
    };
};

$app;
