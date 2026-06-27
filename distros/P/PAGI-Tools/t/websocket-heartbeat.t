use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

use PAGI::WebSocket;

# Helper to create fresh scope for each test
sub make_scope {
    return {
        type    => 'websocket',
        path    => '/test',
        headers => [],
    };
}

my @sent_messages;
my $send = sub {
    my ($msg) = @_;
    push @sent_messages, $msg;
    return Future->done;
};

my $receive = sub { Future->done({ type => 'websocket.connect' }) };

subtest 'keepalive method exists' => sub {
    my $ws = PAGI::WebSocket->new(make_scope(), $receive, $send);
    ok($ws->can('keepalive'), 'keepalive method exists');
};

subtest 'keepalive sends websocket.keepalive event' => sub {
    @sent_messages = ();
    my $ws = PAGI::WebSocket->new(make_scope(), $receive, $send);
    $ws->_set_state('connected');

    $ws->keepalive(30)->get;

    is(scalar @sent_messages, 1, 'one message sent');
    is($sent_messages[0]{type}, 'websocket.keepalive', 'correct event type');
    is($sent_messages[0]{interval}, 30, 'correct interval');
    ok(!exists $sent_messages[0]{timeout}, 'no timeout when not specified');
};

subtest 'keepalive with timeout sends both interval and timeout' => sub {
    @sent_messages = ();
    my $ws = PAGI::WebSocket->new(make_scope(), $receive, $send);
    $ws->_set_state('connected');

    $ws->keepalive(30, 20)->get;

    is(scalar @sent_messages, 1, 'one message sent');
    is($sent_messages[0]{type}, 'websocket.keepalive', 'correct event type');
    is($sent_messages[0]{interval}, 30, 'correct interval');
    is($sent_messages[0]{timeout}, 20, 'correct timeout');
};

subtest 'keepalive returns self for chaining' => sub {
    my $ws = PAGI::WebSocket->new(make_scope(), $receive, $send);
    $ws->_set_state('connected');
    my $result = $ws->keepalive(25)->get;
    is(ref($result), ref($ws), 'returns same type');
    ok($result == $ws, 'returns $self for chaining');
};

subtest 'keepalive with 0 interval disables keepalive' => sub {
    @sent_messages = ();
    my $ws = PAGI::WebSocket->new(make_scope(), $receive, $send);
    $ws->_set_state('connected');

    $ws->keepalive(0)->get;

    is(scalar @sent_messages, 1, 'message sent');
    is($sent_messages[0]{type}, 'websocket.keepalive', 'correct event type');
    is($sent_messages[0]{interval}, 0, 'interval is 0 to disable');
};

subtest 'param method for route parameters' => sub {
    my $scope_with_params = {
        type    => 'websocket',
        path    => '/test',
        headers => [],
        path_params => { id => '42', name => 'test' },
    };
    my $ws = PAGI::WebSocket->new($scope_with_params, $receive, $send);

    is($ws->path_param('id'), '42', 'param returns route parameter');
    is($ws->path_param('name'), 'test', 'param returns another route parameter');
    is($ws->path_param('missing'), undef, 'param returns undef for missing');
};

subtest 'params method returns all route parameters' => sub {
    my $scope_with_params = {
        type    => 'websocket',
        path    => '/test',
        headers => [],
        path_params => { foo => 'bar', baz => 'qux' },
    };
    my $ws = PAGI::WebSocket->new($scope_with_params, $receive, $send);

    my $params = $ws->path_params;
    is($params, { foo => 'bar', baz => 'qux' }, 'params returns all route params');
};

subtest 'param returns undef when no route params in scope' => sub {
    my $ws = PAGI::WebSocket->new(make_scope(), $receive, $send);
    is($ws->path_param('anything'), undef, 'param returns undef when no params');
    is($ws->path_params, {}, 'params returns empty hash when no params');
};

done_testing;
