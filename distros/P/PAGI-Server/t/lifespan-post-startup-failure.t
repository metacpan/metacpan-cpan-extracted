use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Future::IO is an optional (recommends) dependency; skip when its IO::Async
# backend is unavailable, matching t/05-sse.t.
eval { require Future::IO; require Future::IO::Impl::IOAsync; 1 }
    or plan skip_all => 'Future::IO::Impl::IOAsync required for this test';

use PAGI::Server;

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';

# Regression test: a long-lived lifespan task that crashes AFTER startup must
# be surfaced (logged at error level), not silently swallowed. Previously the
# server wrapped the lifespan app in a bare eval whose recovery only fired for
# pre-startup failures, so a background task dying mid-lifetime vanished with no
# log and the server kept running as if nothing happened.

# Lifespan handler announces startup, then its background work crashes shortly
# after -- a genuine post-startup failure.
my $app = async sub {
    my ($scope, $receive, $send) = @_;

    if ($scope->{type} eq 'lifespan') {
        while (1) {
            my $event = await $receive->();
            if ($event->{type} eq 'lifespan.startup') {
                await $send->({ type => 'lifespan.startup.complete' });
                await Future::IO->sleep(0.05);
                die "background task crashed\n";
            }
            elsif ($event->{type} eq 'lifespan.shutdown') {
                await $send->({ type => 'lifespan.shutdown.complete' });
                last;
            }
        }
        return;
    }

    # Minimal HTTP handler (not exercised by this test).
    await $send->({ type => 'http.response.start', status => 200, headers => [] });
    await $send->({ type => 'http.response.body', body => '' });
};

subtest 'post-startup lifespan failure is logged at error level' => sub {
    my $loop = IO::Async::Loop->new;

    my @logged;
    local $SIG{__WARN__} = sub { push @logged, $_[0] };

    my $server = PAGI::Server->new(
        app   => $app,
        host  => '127.0.0.1',
        port  => 0,
        quiet => 1,    # suppress the banner; error-level logs still emit
    );

    $loop->add($server);
    $server->listen->get;    # returns once startup.complete is received

    ok($server->is_running, 'server started (startup completed before the crash)');

    # Let the background task crash.
    $loop->delay_future(after => 0.3)->get;

    ok(
        (scalar grep { /Lifespan app failed after startup/ } @logged),
        'server logs an error when the lifespan app fails after startup'
    ) or diag("captured warnings: @logged");

    like(
        join('', @logged),
        qr/background task crashed/,
        'logged error includes the original failure message'
    );

    $loop->remove($server);
};

done_testing;
