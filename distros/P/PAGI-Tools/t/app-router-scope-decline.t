use strict;
use warnings;

use Test2::V0;
use Future::AsyncAwait;

use PAGI::App::Router;

# An unmatched route must answer with the event family that matches the scope:
# plain http.response.* on http, but the namespaced decline events
# sse.http.response.* / websocket.http.response.* on those scopes. Emitting a
# plain http.response.* on an sse/websocket scope raises on a conforming server
# (the per-scope send-dispatch has no http.response.* branch), so an unmatched
# SSE/WS route would crash the connection instead of returning a 404.

sub mock_send {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    return ($send, \@sent);
}

subtest 'unmatched HTTP route -> plain http.response.* 404 (regression)' => sub {
    my $router = PAGI::App::Router->new;
    my $app = $router->to_app;

    my ($send, $sent) = mock_send();
    $app->({ method => 'GET', path => '/nope' }, sub { Future->done }, $send)->get;

    is $sent->[0]{type},   'http.response.start', 'start event is http.response.start';
    is $sent->[0]{status}, 404,                   'status 404';
    is $sent->[1]{type},   'http.response.body',  'body event is http.response.body';
};

subtest 'unmatched SSE route -> sse.http.response.* 404' => sub {
    my $router = PAGI::App::Router->new;
    my $app = $router->to_app;

    my ($send, $sent) = mock_send();
    $app->({ type => 'sse', path => '/nope' }, sub { Future->done }, $send)->get;

    is $sent->[0]{type},   'sse.http.response.start', 'start event is namespaced for sse';
    is $sent->[0]{status}, 404,                       'status 404';
    is $sent->[1]{type},   'sse.http.response.body',  'body event is namespaced for sse';
    is $sent->[1]{more},   0,                         'body closes the response';
};

subtest 'unmatched WebSocket route -> websocket.http.response.* 404' => sub {
    my $router = PAGI::App::Router->new;
    my $app = $router->to_app;

    my ($send, $sent) = mock_send();
    $app->({ type => 'websocket', path => '/nope' }, sub { Future->done }, $send)->get;

    is $sent->[0]{type},   'websocket.http.response.start', 'start event is namespaced for ws';
    is $sent->[0]{status}, 404,                             'status 404';
    is $sent->[1]{type},   'websocket.http.response.body',  'body event is namespaced for ws';
    is $sent->[1]{more},   0,                               'body closes the response';
};

subtest 'custom not_found handler is still delegated to on every scope' => sub {
    my @seen;
    my $not_found = async sub {
        my ($scope, $receive, $send) = @_;
        push @seen, $scope->{type} // 'http';
    };
    my $router = PAGI::App::Router->new(not_found => $not_found);
    my $app = $router->to_app;

    for my $scope ({ method => 'GET', path => '/x' },
                   { type => 'sse', path => '/x' },
                   { type => 'websocket', path => '/x' }) {
        my ($send, $sent) = mock_send();
        $app->($scope, sub { Future->done }, $send)->get;
        is scalar(@$sent), 0, "not_found suppresses the default decline ($scope->{type})"
            if defined $scope->{type};
    }

    is \@seen, ['http', 'sse', 'websocket'], 'not_found invoked for all three scopes';
};

done_testing;
