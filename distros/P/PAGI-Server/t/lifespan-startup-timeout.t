use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PAGI::Server;

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';

# A lifespan handler that hangs during startup -- it awaits the startup event
# and then never sends lifespan.startup.complete (or fails). Without a startup
# timeout the server blocks forever on `await $startup_complete`. With one, it
# must give up and fail startup with a clear error instead of hanging.
my $app = async sub {
    my ($scope, $receive, $send) = @_;

    if ($scope->{type} eq 'lifespan') {
        await $receive->();      # lifespan.startup
        await Future->new;       # hang: never signal startup
    }

    await $send->({ type => 'http.response.start', status => 200, headers => [] });
    await $send->({ type => 'http.response.body', body => '' });
};

subtest 'a lifespan startup that never signals times out instead of hanging' => sub {
    my $loop = IO::Async::Loop->new;

    my $server = PAGI::Server->new(
        app                      => $app,
        host                     => '127.0.0.1',
        port                     => 0,
        quiet                    => 1,
        lifespan_startup_timeout => 0.3,
    );
    $loop->add($server);

    my $err = dies { $server->listen->get };
    ok($err, 'listen failed instead of hanging') or diag('listen returned without error');
    like($err, qr/startup timed out/i, 'error mentions the startup timeout');

    $loop->remove($server);
};

done_testing;
