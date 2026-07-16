package Example::Middleware::RequestTimer;
use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use Time::HiRes ();
use parent 'PAGI::Middleware';

# Event-layer middleware (subclass PAGI::Middleware, implement wrap). It times
# the request and injects an X-Response-Time-Ms header by wrapping $send: when
# the response start event passes through, it appends the header. Wrapping the
# channel like this is how a middleware shapes the response without the handler
# knowing or caring.

sub wrap ($self, $app) {
    return async sub ($scope, $receive, $send) {
        my $t0 = Time::HiRes::time();

        my $timing_send = async sub ($event) {
            if (ref $event eq 'HASH' && ($event->{type} // '') eq 'http.response.start') {
                my $ms = sprintf('%.1f', (Time::HiRes::time() - $t0) * 1000);
                my @headers = (@{ $event->{headers} // [] }, ['x-response-time-ms', $ms]);
                $event = { %$event, headers => \@headers };
            }
            await $send->($event);
        };

        await $app->($scope, $receive, $timing_send);
    };
}

1;
