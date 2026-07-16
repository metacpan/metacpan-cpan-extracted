use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use PAGI::Nano;

# Ports PAGI-Tools' full-demo (and PAGI's reference showcase) to PAGI::Nano.
# One app exercising every protocol: HTTP (plain + JSON echo + streaming),
# WebSocket echo, SSE ticks, and lifespan-managed shared state.
#
#     pagi-server app.pl

my $app = app {
    startup async sub ($state) { $state->{requests} = 0; $state->{started} = 'yes' };
    shutdown async sub ($state) { warn "served $state->{requests} requests\n" };

    enable 'GZip';

    get '/' => sub ($c) {
        $c->state->{requests}++;
        { app => 'PAGI::Nano full-demo', requests => $c->state->{requests} };
    };

    post '/echo' => async sub ($c) {
        my $clean = await $c->params->permitted('message');
        $c->json({ you_said => $clean->{message} });
    };

    get '/stream' => sub ($c) {
        $c->response->stream(async sub ($w) {
            for my $i (1 .. 3) { await $w->write("line $i\n") }
            await $w->close;
        });
    };

    websocket '/ws/echo' => async sub ($c) {
        my $ws = $c->websocket;
        await $ws->accept;
        await $ws->each_text(async sub ($t) { await $ws->send_text("echo: $t") });
    };

    sse '/events' => async sub ($c) {
        my $s = $c->sse;
        for my $i (1 .. 3) { await $s->send("tick $i") }
        await $s->close;
    };
};

$app;
