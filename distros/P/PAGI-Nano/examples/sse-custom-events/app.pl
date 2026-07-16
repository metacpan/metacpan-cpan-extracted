use v5.40;
use experimental 'signatures';
use Future;
use Future::AsyncAwait;
use Future::IO;
use PAGI::Nano;

# Custom SSE events, delivered through $receive the composable way (the SSE
# evolution of PAGI's 17-event-middleware). One event stream carries TWO custom
# event types from two sources, folded onto the same channel by a middleware:
#
#   tick    -> periodic, from a timer source
#   message -> user-driven: any client POSTs to /say, broadcast to ALL /events
#              subscribers
#
# A middleware owns the fold: for the SSE stream it races the next protocol event
# against the next bus event WITHOUT cancelling the long-lived $receive (cancelling
# it would end the connection). The handler is pure — it awaits the next event and
# switches on type — and SSE's native `event:` field surfaces the custom type.
#
#     pagi-server app.pl
#     # one terminal — watch the stream (the Accept header is what promotes the
#     # request to SSE; a browser's EventSource sends it automatically):
#     curl -N -H 'Accept: text/event-stream' http://127.0.0.1:5000/events
#     # another terminal — anyone can broadcast a message to every subscriber:
#     curl -XPOST http://127.0.0.1:5000/say -d 'hello everyone'
#
# See probe.pl for a self-contained proof that a POSTed message reaches an open
# SSE stream.

# A tiny pub/sub bus carrying typed events. A subscriber gets a Future that
# resolves on the next published event; publish drains every current waiter.
package EventBus {
    use experimental 'signatures';
    sub new ($class)        { bless { waiters => [] }, $class }
    sub next_event ($self)  { push @{ $self->{waiters} }, my $f = Future->new; $f }
    sub publish ($self, $event) {
        # done() on a waiter cancelled by a lost race is a harmless no-op. Note
        # this is a simple in-memory bus: a subscriber momentarily between events
        # (not currently parked on next_event) can miss a publish. A production
        # bus would queue per subscriber.
        $_->done($event) for splice @{ $self->{waiters} };
    }
}

# Resolve as soon as ANY of the given futures is ready, cancelling none of them.
async sub await_either (@futures) {
    my $first = Future->new;
    $_->on_ready(sub { $first->done unless $first->is_ready }) for @futures;
    await $first;
    return;
}

# The middleware: for the SSE stream, fold the bus's events into $receive so they
# arrive alongside the protocol events. Gated to the SSE scope — HTTP requests
# (including POST /say) get a clean, unwrapped $receive so body reading is intact.
my $with_events = async sub ($scope, $receive, $send, $next) {
    my $bus = $scope->{state}{bus};
    return await $next->()
        unless $bus && ($scope->{type} // '') eq 'sse';

    my $protocol_f;
    my $wrapped_receive = async sub {
        $protocol_f //= $receive->();          # one outstanding receive, kept alive
        my $event_f = $bus->next_event;
        await await_either($protocol_f, $event_f);
        if ($protocol_f->is_ready) {           # a protocol event arrived
            my $event = $protocol_f->get;
            undef $protocol_f;                 # consumed -> fetch a fresh one next time
            return $event;
        }
        return $event_f->get;                  # a bus event (already typed)
    };
    await $next->($scope, $wrapped_receive, $send);
};

my $app = app {
    # The bus and its timer source live for the app's lifetime, shared by all
    # requests via state (one per worker).
    startup async sub ($state) {
        my $bus = EventBus->new;
        $state->{bus}    = $bus;
        $state->{ticker} = (async sub {
            my $n = 0;
            while (1) {
                await Future::IO->sleep(1);
                $bus->publish({ type => 'tick', count => ++$n });
            }
        })->();
    };
    shutdown async sub ($state) {
        $state->{ticker}->cancel if $state->{ticker};
    };

    enable $with_events;

    # The SSE stream is pure: it knows nothing about the bus. It awaits the next
    # event and switches on type — tick, message, and the disconnect all arrive
    # through $receive — emitting a named SSE event for each.
    sse '/events' => async sub ($c) {
        my $s = $c->sse;
        await $s->start;                       # establish the stream immediately
        while (1) {
            my $event = await $c->receive->();
            my $type  = $event->{type} // '';
            if ($type eq 'tick') {
                await $s->send_event(event => 'tick', data => $event->{count});
            }
            elsif ($type eq 'message') {
                await $s->send_event(event => 'message', data => $event->{text});
            }
            elsif ($type eq 'sse.disconnect') {
                last;                          # client went away
            }
            # other protocol events are ignored
        }
        await $s->close;
    };

    # The user-driven source: a POST publishes a message event to the bus, which
    # the middleware folds into every open SSE stream.
    post '/say' => async sub ($c) {
        my $text = await $c->req->body;
        $text =~ s/\s+\z//;                    # trim trailing newline
        $c->state->{bus}->publish({ type => 'message', text => $text });
        $c->json({ ok => 1, broadcast => $text }, status => 202);
    };
};

$app;
