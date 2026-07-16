use v5.40;
use experimental 'signatures';
use Future;
use Future::AsyncAwait;
use Future::IO;
use PAGI::Nano;

# Ports PAGI's 14-periodic-events to PAGI::Nano.
# A background ticker is rooted in the lifespan (it lives for the app's lifetime)
# and publishes to an in-memory hub shared via $c->state. Request handlers read
# the current count, long-poll for the next tick, or stream ticks as NDJSON.
#
#     pagi-server app.pl
#     curl http://127.0.0.1:5000/            # immediate count
#     curl -N http://127.0.0.1:5000/stream   # NDJSON tick stream

# A tiny pub/sub hub: a counter plus Futures waiting for the next tick.
package Hub {
    use Future;
    sub new ($class) { bless { count => 0, waiters => [] }, $class }
    sub count ($self) { $self->{count} }
    sub next_tick ($self) {
        my $f = Future->new;
        push @{ $self->{waiters} }, $f;
        return $f;
    }
    sub tick ($self) {
        $self->{count}++;
        my @waiters = @{ $self->{waiters} };
        $self->{waiters} = [];
        $_->done($self->{count}) for @waiters;
    }
}

my $app = app {
    startup async sub ($state) {
        my $hub = Hub->new;
        $state->{hub} = $hub;
        # Recurring background ticker, retained for the app lifetime.
        $state->{ticker} = (async sub {
            while (1) {
                await Future::IO->sleep(1);
                $hub->tick;
            }
        })->();
    };

    # Cancel the ticker on shutdown: discarding a suspended async sub without
    # cancelling it warns ("lost its returning future") and leaves its pending
    # timer armed. Cancellation is the clean end for a background task.
    shutdown async sub ($state) {
        $state->{ticker}->cancel;
    };

    get '/' => sub ($c) { { ticks => $c->state->{hub}->count } };

    get '/next' => async sub ($c) {
        my $n = await $c->state->{hub}->next_tick;   # long-poll
        { tick => $n };
    };

    get '/stream' => sub ($c) {
        my $hub = $c->state->{hub};
        $c->response->stream(async sub ($w) {
            for my $i (1 .. 3) {
                my $n = await $hub->next_tick;
                await $w->write(qq({"tick":$n}\n));   # NDJSON
            }
            await $w->close;
        });
    };
};

$app;
