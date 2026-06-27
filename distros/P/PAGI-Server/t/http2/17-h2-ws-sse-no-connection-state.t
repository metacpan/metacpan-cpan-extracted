use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/../../lib";

use PAGI::Server::Connection;

# SYNC B1: pagi.connection is HTTP-only. The spec marks it NOT APPLICABLE for
# websocket/sse scopes (they use their own *.disconnect events). HTTP/1.1
# correctly omits it; the HTTP/2 scope builders used to set it on websocket and
# sse scopes too -- both a spec violation and an h1/h2 inconsistency. These
# builders are pure functions of $self + the per-stream state, so we can call
# them directly with a minimal fake connection (no nghttp2 handshake needed).

# Minimal duck-typed Connection: the builders only read these fields and call
# _get_scheme / _get_ws_scheme / _get_extensions_for_scope (all trivial).
sub fake_conn {
    return bless {
        tls_enabled => 0,
        extensions  => {},
        client_host => '127.0.0.1',
        client_port => 54321,
        server_host => '127.0.0.1',
        server_port => 8080,
        state       => {},
    }, 'PAGI::Server::Connection';
}

my $stream_state = {
    pseudo => {
        ':path'      => '/stream',
        ':method'    => 'GET',
        ':scheme'    => 'http',
        ':authority' => 'localhost',
    },
    headers => [],
};

subtest 'HTTP/2 websocket scope omits pagi.connection' => sub {
    my $scope = fake_conn()->_h2_create_websocket_scope(1, $stream_state);
    is($scope->{type}, 'websocket', 'built a websocket scope');
    ok(!exists $scope->{'pagi.connection'},
        'websocket scope must NOT carry pagi.connection (NOT APPLICABLE)');
};

subtest 'HTTP/2 sse scope omits pagi.connection' => sub {
    my $scope = fake_conn()->_h2_create_sse_scope(1, $stream_state);
    is($scope->{type}, 'sse', 'built an sse scope');
    ok(!exists $scope->{'pagi.connection'},
        'sse scope must NOT carry pagi.connection (NOT APPLICABLE)');
};

subtest 'HTTP/2 http scope still carries pagi.connection (control)' => sub {
    my $scope = fake_conn()->_h2_create_scope(1, $stream_state);
    is($scope->{type}, 'http', 'built an http scope');
    ok(exists $scope->{'pagi.connection'},
        'http scope MUST still provide pagi.connection');
};

done_testing;
