use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PAGI::Server;
use PAGI::Server::Connection;
use PAGI::Server::ConnectionState;

# response_started must become true once THIS request's response has started --
# whether the app produced it (HTTP/1.1 + HTTP/2) or the server synthesized a
# 500 backstop -- and each HTTP/2 stream must carry its OWN flag (no cross-stream
# contamination).

# --------------------------------------------------------------------------
# HTTP/2: each stream gets its own per-stream connection object (no network).
# _h2_create_scope is a pure function of $self + the per-stream state; we drive
# it directly with a minimal fake connection, mocking only the two helpers that
# would otherwise touch a live nghttp2 session.
# --------------------------------------------------------------------------
subtest 'HTTP/2 streams get independent per-stream connection objects' => sub {
    no warnings 'redefine';
    local *PAGI::Server::Connection::_h2_transport_state       = sub { undef };
    local *PAGI::Server::Connection::_get_extensions_for_scope = sub { {} };

    my $conn = bless {
        tls_enabled => 0,
        client_host => '127.0.0.1', client_port => 1,
        server_host => '127.0.0.1', server_port => 8080,
        state       => {},
    }, 'PAGI::Server::Connection';

    my $ss_a = { pseudo => { ':path' => '/a', ':method' => 'GET', ':scheme' => 'http', ':authority' => 'localhost' }, headers => [] };
    my $ss_b = { pseudo => { ':path' => '/b', ':method' => 'GET', ':scheme' => 'http', ':authority' => 'localhost' }, headers => [] };

    my $scope_a = PAGI::Server::Connection::_h2_create_scope($conn, 1, $ss_a);
    my $scope_b = PAGI::Server::Connection::_h2_create_scope($conn, 3, $ss_b);

    ok $ss_a->{connection_state}, 'stream A: connection_state stored on stream-state';
    ok $ss_b->{connection_state}, 'stream B: connection_state stored on stream-state';
    ref_is_not($ss_a->{connection_state}, $ss_b->{connection_state}, 'distinct objects per stream');
    ref_is($scope_a->{'pagi.connection'}, $ss_a->{connection_state}, 'scope pagi.connection is the stored object');

    is($ss_a->{connection_state}->response_started, 0, 'A not started');
    is($ss_b->{connection_state}->response_started, 0, 'B not started');

    # What the per-stream send path does when stream A emits http.response.start:
    $ss_a->{connection_state}->_mark_response_started;
    is($ss_a->{connection_state}->response_started, 1, 'A started after its mark');
    is($ss_b->{connection_state}->response_started, 0, 'B unaffected -- no cross-stream contamination');
};

# --------------------------------------------------------------------------
# HTTP/1.1 integration through the real server.
# --------------------------------------------------------------------------
SKIP: {
    skip 'Set INTEGRATION_TEST=1 to run HTTP/1.1 integration', 1
        unless $ENV{INTEGRATION_TEST};

    require IO::Async::Loop;
    require Net::Async::HTTP;

    my $loop = IO::Async::Loop->new;
    my @rec;   # one record per request: { path, conn, before, after }

    my $app = async sub {
        my ($scope, $receive, $send) = @_;

        if ($scope->{type} eq 'lifespan') {
            while (1) {
                my $event = await $receive->();
                if ($event->{type} eq 'lifespan.startup') {
                    await $send->({ type => 'lifespan.startup.complete' });
                }
                elsif ($event->{type} eq 'lifespan.shutdown') {
                    await $send->({ type => 'lifespan.shutdown.complete' });
                    last;
                }
            }
            return;
        }

        my $conn = $scope->{'pagi.connection'};
        my $r = { path => $scope->{path}, conn => $conn, before => $conn->response_started };
        push @rec, $r;

        return if $scope->{path} eq '/nothing';   # produce no response -> server backstop

        await $send->({ type => 'http.response.start', status => 200, headers => [['content-type', 'text/plain']] });
        $r->{after} = $conn->response_started;
        await $send->({ type => 'http.response.body', body => 'ok', more => 0 });
    };

    my $server = PAGI::Server->new(app => $app, port => 0, quiet => 1);
    $loop->add($server);
    $server->listen->get;
    my $port = $server->port;

    my $http = Net::Async::HTTP->new(pipeline => 0);
    $loop->add($http);

    subtest 'an app response marks response_started' => sub {
        @rec = ();
        my $res = $http->GET("http://127.0.0.1:$port/respond")->get;
        is($res->code, 200, '/respond -> 200');
        $loop->loop_once(0) for 1 .. 5;
        is($rec[0]{before}, 0, 'response_started false before the send');
        is($rec[0]{after},  1, 'response_started true after http.response.start');
    };

    subtest 'keep-alive: request 2 starts fresh at 0 (per-request object)' => sub {
        @rec = ();
        $http->GET("http://127.0.0.1:$port/respond")->get;
        $http->GET("http://127.0.0.1:$port/respond")->get;
        $loop->loop_once(0) for 1 .. 5;
        is(scalar(@rec), 2, 'two sequential requests handled');
        is($rec[1]{before}, 0, 'request 2 response_started begins at 0');
    };

    subtest 'a server-synthesized 500 marks response_started' => sub {
        @rec = ();
        my $res = $http->GET("http://127.0.0.1:$port/nothing")->get;
        is($res->code, 500, 'server backstop -> 500');
        $loop->loop_once(0) for 1 .. 5;
        is($rec[0]{conn}->response_started, 1, 'response_started true after the server backstop');
    };

    $server->shutdown->get;
    $loop->remove($server);
    $loop->remove($http);
}

done_testing;
