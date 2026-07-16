use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use PAGI::Nano;

# Ports PAGI's 04-websocket-echo (and PAGI-Tools' websocket-echo-v2) to
# PAGI::Nano. A WebSocket handler is imperative: accept, then echo each frame.
#
#     pagi-server app.pl
#     websocat ws://127.0.0.1:5000/

my $app = app {
    websocket '/' => async sub ($c) {
        my $ws = $c->websocket;
        await $ws->accept;
        await $ws->each_text(async sub ($text) {
            await $ws->send_text("echo: $text");
        });
    };
};

$app;
