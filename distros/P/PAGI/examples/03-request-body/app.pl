use strict;
use warnings;
use Future::AsyncAwait;

async sub read_body {
    my ($receive) = @_;

    my $body = '';
    while (1) {
        my $event = await $receive->();
        last if $event->{type} ne 'http.request';
        $body .= $event->{body} // '';
        last unless $event->{more};
    }
    return $body;
}

async sub app {
    my ($scope, $receive, $send) = @_;

    die "Unsupported scope type: $scope->{type}" if $scope->{type} ne 'http';

    my $body = await read_body($receive);
    my $message = length $body
        ? "You sent: $body"
        : "No body provided";

    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [ [ 'content-type', 'text/plain' ] ],
    });

    await $send->({ type => 'http.response.body', body => $message, more => 0 });
}

\&app;
