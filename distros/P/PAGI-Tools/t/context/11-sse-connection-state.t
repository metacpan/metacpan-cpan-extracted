use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use PAGI::Context;
use PAGI::SSE;

# is_connected on an SSE scope must reflect the SSE wrapper's own state machine
# (pending -> started -> closed), exactly like PAGI::WebSocket/Context::WebSocket
# do (connecting -> connected -> closed). SSE scopes carry no pagi.connection
# (spec: N/A), so the base Context::is_connected — which reads pagi.connection —
# is wrong for SSE and must be overridden.

sub make_sse_ctx {
    my @sent;
    my $send = sub { push @sent, $_[0]; Future->done };
    my $scope = { type => 'sse', path => '/events', headers => [] };
    my $ctx = PAGI::Context->new($scope, sub { Future->new }, $send);
    return ($ctx, \@sent);
}

subtest 'Context::SSE is_connected uses SSE state (not base/pagi.connection)' => sub {
    my ($ctx, $sent) = make_sse_ctx();

    ok(!$ctx->is_connected, 'not connected before start (state pending)');
    ok($ctx->is_disconnected, 'is_disconnected true before start');

    $ctx->start->get;
    ok($ctx->is_connected, 'connected on a live stream (state started)');
    ok(!$ctx->is_disconnected, 'is_disconnected false on a live stream');

    $ctx->close->get;
    ok(!$ctx->is_connected, 'not connected after close');
    ok($ctx->is_disconnected, 'is_disconnected true after close');
};

subtest 'PAGI::SSE->is_connected mirrors is_started && !is_closed' => sub {
    my @sent;
    my $send = sub { push @sent, $_[0]; Future->done };
    my $scope = { type => 'sse', path => '/e', headers => [] };
    my $sse = PAGI::SSE->new($scope, sub { Future->new }, $send);

    ok(!$sse->is_connected, 'pending: not connected');
    $sse->start->get;
    ok($sse->is_connected, 'started: connected');
    $sse->close->get;
    ok(!$sse->is_connected, 'closed: not connected');
};

done_testing;
