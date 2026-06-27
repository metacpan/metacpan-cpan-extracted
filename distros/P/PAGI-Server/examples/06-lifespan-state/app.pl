use strict;
use warnings;
use Future::AsyncAwait;

async sub handle_lifespan {
    my ($scope, $receive, $send) = @_;

    my $state = $scope->{state} //= {};

    while (1) {
        my $event = await $receive->();
        if ($event->{type} eq 'lifespan.startup') {
            $state->{greeting} = 'Hello from lifespan';
            await $send->({ type => 'lifespan.startup.complete' });
        }
        elsif ($event->{type} eq 'lifespan.shutdown') {
            await $send->({ type => 'lifespan.shutdown.complete' });
            last;
        }
    }
}

async sub handle_http {
    my ($scope, $receive, $send) = @_;

    my $state = $scope->{state} // {};
    my $greeting = $state->{greeting} // 'Hello';

    # Drain the request body (if any)
    while (1) {
        my $event = await $receive->();
        last if $event->{type} ne 'http.request';
        last unless $event->{more};
    }

    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [ [ 'content-type', 'text/plain' ] ],
    });

    await $send->({ type => 'http.response.body', body => "$greeting via shared state", more => 0 });
}

async sub app {
    my ($scope, $receive, $send) = @_;

    return await handle_lifespan($scope, $receive, $send) if $scope->{type} eq 'lifespan';
    return await handle_http($scope, $receive, $send)      if $scope->{type} eq 'http';
    die "Unsupported scope type: $scope->{type}";
}

\&app;
