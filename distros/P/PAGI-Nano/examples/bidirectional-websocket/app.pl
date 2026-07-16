use v5.40;
use experimental 'signatures';
use Future;
use Future::AsyncAwait;
use Future::IO;
use PAGI::Nano;

# Ports PAGI's 18-bidirectional-websocket (and PAGI-Tools' websocket-bidirectional)
# to PAGI::Nano. $receive and $send are independent, so a single connection runs
# two concurrent branches: one echoes client messages, one pushes server ticks
# unsolicited. Future->wait_any ties them together so a disconnect cancels both.
#
#     pagi-server app.pl
#     websocat ws://127.0.0.1:5000/

my $app = app {
    websocket '/' => async sub ($c) {
        my $ws = $c->websocket;
        await $ws->accept;

        my $incoming = async sub {
            await $ws->each_text(async sub ($text) {
                await $ws->send_text("echo: $text");
            });
        };

        my $outgoing = async sub {
            my $n = 0;
            while ($ws->is_connected) {
                await $ws->send_text_if_connected('tick ' . ++$n);
                await Future::IO->sleep(1);
            }
        };

        await Future->wait_any($incoming->(), $outgoing->());
    };
};

$app;
