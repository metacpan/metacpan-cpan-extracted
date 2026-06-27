use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Net::Async::HTTP;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PAGI::Server;

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';

# An application that does NOT implement lifespan declines it by RETURNING
# cleanly on the lifespan scope (the idiomatic decline -- no startup.complete,
# no exception), exactly as examples/14-periodic-events does. The server must
# treat a clean return without startup.complete as "lifespan not supported",
# start normally, and serve requests -- it must not error or hang at startup.
my $app = async sub {
    my ($scope, $receive, $send) = @_;

    return unless ($scope->{type} // '') eq 'http';    # decline lifespan by returning

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
    await $send->({ type => 'http.response.body', body => 'ok', more => 0 });
};

subtest 'app that declines lifespan by returning cleanly still starts and serves' => sub {
    my $loop = IO::Async::Loop->new;

    my $server = PAGI::Server->new(
        app   => $app,
        host  => '127.0.0.1',
        port  => 0,
        quiet => 1,
    );
    $loop->add($server);

    my $started = eval { $server->listen->get; 1 };
    ok($started, 'server started despite the app declining lifespan by clean return')
        or diag("listen failed: $@");

    SKIP: {
        skip "server did not start", 1 unless $started;

        my $port = $server->port;
        my $http = Net::Async::HTTP->new;
        $loop->add($http);

        my $response = $http->GET("http://127.0.0.1:$port/")->get;
        is($response->code, 200, 'serves HTTP after declining lifespan');

        $server->shutdown->get;
        $loop->remove($http);
    }

    $loop->remove($server);
};

done_testing;
