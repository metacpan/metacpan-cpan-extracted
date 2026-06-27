#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request;

use lib 'lib';
use PAGI::Server;

# Exercises the real server completion path: pagi.connection->on_complete must
# fire when a request finishes cleanly, and on_disconnect must NOT, on both the
# keep-alive and the connection-close paths.
#
# The test process *is* the server (same event loop), and on_complete fires
# synchronously when the handler returns -- before the client finishes reading
# the body -- so the shared @log is populated by the time ->get resolves.
plan skip_all => 'Set INTEGRATION_TEST=1 to run' unless $ENV{INTEGRATION_TEST};

my $loop = IO::Async::Loop->new;

# Server-side log of which terminal callback fired (lexical closure).
my @log;

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

    # Register both terminal callbacks; exactly one must fire per request.
    my $conn = $scope->{'pagi.connection'};
    $conn->on_disconnect(sub { push @log, "disconnect:$_[0]" });
    $conn->on_complete(sub  { push @log, 'complete' });

    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [['content-type', 'text/plain']],
    });
    await $send->({ type => 'http.response.body', body => 'ok', more => 0 });
};

my $server = PAGI::Server->new(app => $app, port => 0, quiet => 1);
$loop->add($server);
$server->listen->get;
my $port = $server->port;

my $http = Net::Async::HTTP->new(pipeline => 0);
$loop->add($http);

subtest 'on_complete fires on clean completion (keep-alive)' => sub {
    @log = ();
    my $res = $http->GET("http://127.0.0.1:$port/work")->get;
    is($res->code, 200, '/work responded 200');
    $loop->loop_once(0) for 1 .. 5;   # insurance: let any deferred work settle
    is(\@log, ['complete'],
        'on_complete fired, on_disconnect did not (keep-alive completion)');
};

subtest 'on_complete fires on clean completion (connection: close)' => sub {
    @log = ();
    my $req = HTTP::Request->new(
        GET => "http://127.0.0.1:$port/close",
        ['Connection' => 'close'],
    );
    my $res = $http->do_request(request => $req)->get;
    is($res->code, 200, '/close responded 200');
    $loop->loop_once(0) for 1 .. 5;
    is(\@log, ['complete'],
        'on_complete fired, on_disconnect did not (non-keep-alive completion)');
};

$server->shutdown->get;
$loop->remove($server);
$loop->remove($http);

done_testing;
