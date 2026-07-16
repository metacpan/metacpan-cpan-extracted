use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use JSON::MaybeXS qw(encode_json);
use PAGI::Nano;

# Custom SEND events: the mirror of sse-custom-events. There, a middleware folds
# custom events INTO $receive. Here, the handler emits high-level, semantic events
# and a middleware translates them OUT of $send into the wire protocol — exactly
# the mechanism PAGI's own SSE/WebSocket are built on (sse.send and websocket.send
# are custom send events a server-side layer renders).
#
# The payoff: the handler speaks pure domain — app.start, app.event{name,data},
# app.end — and never names a wire format. ONE handler is served at /feed in TWO
# formats, chosen by content negotiation:
#
#   curl -N -H 'Accept: text/event-stream' http://127.0.0.1:5000/feed   # SSE
#   curl -N                                http://127.0.0.1:5000/feed   # NDJSON
#
# The Accept header makes the server route the request to the sse scope (and the
# SSE renderer); without it, it is a plain HTTP request handled by the `raw`
# escape-hatch route (and the NDJSON renderer). Same handler, two route-scoped
# middlewares, two wire formats — the handler is untouched. `raw` is what lets the
# imperative "emit events, let a middleware render" handler run over plain HTTP
# (an ordinary coerced handler must return a response).

# The handler: pure domain events on the raw send channel. $c->raw_send gives the
# raw $send on any context — needed on the SSE route, whose $c->send is the SSE
# message convenience; on the HTTP (raw) route $c->send would already do.
my $emit_events = async sub ($c) {
    my $emit = $c->raw_send;
    await $emit->({ type => 'app.start' });
    for my $event (
        { name => 'status', data => 'online' },
        { name => 'tick',   data => 1 },
        { name => 'tick',   data => 2 },
        { name => 'status', data => 'offline' },
    ) {
        await $emit->({ type => 'app.event', %$event });
    }
    await $emit->({ type => 'app.end' });
};

# Renderer A: domain events -> Server-Sent Events, enriched with a sequence number.
my $render_sse = async sub ($scope, $receive, $send, $next) {
    my $seq = 0;
    my $wrapped = async sub ($event) {
        my $type = $event->{type} // '';
        if    ($type eq 'app.start') { await $send->({ type => 'sse.start', status => 200 }) }
        elsif ($type eq 'app.event') {
            $seq++;
            await $send->({
                type  => 'sse.send',
                event => $event->{name},
                data  => encode_json({ value => $event->{data}, seq => $seq }),
            });
        }
        elsif ($type eq 'app.end') { }   # the server closes the SSE stream when the handler returns
        else { await $send->($event) }
    };
    await $next->($scope, $receive, $wrapped);
};

# Renderer B: the SAME domain events -> NDJSON over a plain HTTP stream.
my $render_ndjson = async sub ($scope, $receive, $send, $next) {
    my $seq = 0;
    my $wrapped = async sub ($event) {
        my $type = $event->{type} // '';
        if ($type eq 'app.start') {
            await $send->({
                type    => 'http.response.start',
                status  => 200,
                headers => [['content-type', 'application/x-ndjson']],
            });
        }
        elsif ($type eq 'app.event') {
            $seq++;
            await $send->({
                type => 'http.response.body',
                body => encode_json({ event => $event->{name}, value => $event->{data}, seq => $seq }) . "\n",
                more => 1,
            });
        }
        elsif ($type eq 'app.end') {
            await $send->({ type => 'http.response.body', body => '', more => 0 });
        }
        else { await $send->($event) }
    };
    await $next->($scope, $receive, $wrapped);
};

my $app = app {
    # Same path, same handler — the renderer is the only thing that differs.
    sse '/feed' => middleware($render_sse)    => $emit_events;   # Accept: text/event-stream
    raw '/feed' => middleware($render_ndjson) => $emit_events;   # plain HTTP
};

$app;
