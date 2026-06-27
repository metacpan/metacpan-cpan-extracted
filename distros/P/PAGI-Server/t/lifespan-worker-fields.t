#!/usr/bin/env perl

# =============================================================================
# Test: Lifespan scope includes worker fields (PAGI spec compliance)
#
# Per lifespan.mkdn:
# - pagi["is_worker"] (Int, optional) - 1 if running as a worker, 0 otherwise
# - pagi["worker_num"] (Int, optional) - Worker identifier (1, 2, 3, ...)
# =============================================================================

use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/../lib";
use PAGI::Server;

subtest 'lifespan scope includes worker fields' => sub {
    # Read the Server.pm source
    my $source = do {
        open my $fh, '<', 'lib/PAGI/Server.pm' or die "Cannot read: $!";
        local $/;
        <$fh>;
    };

    # Find the lifespan scope creation
    like(
        $source,
        qr/type\s*=>\s*'lifespan'/,
        'lifespan scope creation exists'
    );

    # Verify is_worker is included in pagi hashref
    like(
        $source,
        qr/is_worker\s*=>\s*\$self->\{is_worker\}/,
        'is_worker field is included in pagi hashref'
    );

    # Verify worker_num is included in pagi hashref
    like(
        $source,
        qr/worker_num\s*=>\s*\$self->\{worker_num\}/,
        'worker_num field is included in pagi hashref'
    );
};

subtest 'worker fields are set during worker process creation' => sub {
    my $source = do {
        open my $fh, '<', 'lib/PAGI/Server.pm' or die "Cannot read: $!";
        local $/;
        <$fh>;
    };

    # Verify is_worker is set to 1 in worker process
    like(
        $source,
        qr/\{is_worker\}\s*=\s*1/,
        'is_worker is set to 1 in worker process'
    );

    # Verify worker_num is assigned from the worker number parameter
    like(
        $source,
        qr/\{worker_num\}\s*=\s*\$worker_num/,
        'worker_num is assigned from worker number'
    );
};

# Behavioral conformance: per PAGI::Spec::Lifespan the lifespan scope's `state`
# is a HashRef (or omitted if unsupported) -- never undef. PAGI::Server supports
# it, so it must always be a defined, writable HashRef the app populates.
subtest 'lifespan scope state is a HashRef the app can populate' => sub {
    my ($state_defined, $state_ref, $write_ok);

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        return unless $scope->{type} eq 'lifespan';

        $state_defined = defined($scope->{state}) ? 1 : 0;
        $state_ref     = ref($scope->{state});
        # The spec calls state "a namespace where the application can persist
        # values" -- so it must be a live, writable HashRef.
        $write_ok = eval { $scope->{state}{ready} = 1; 1 } ? 1 : 0;

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
    };

    my $loop   = IO::Async::Loop->new;
    my $server = PAGI::Server->new(app => $app, port => 0, quiet => 1);
    $loop->add($server);
    $server->listen->get;

    ok($state_defined, 'lifespan scope state is defined (never undef)');
    is($state_ref, 'HASH', 'lifespan scope state is a HashRef');
    ok($write_ok, 'app can persist values into state');

    $server->shutdown->get;
    $loop->remove($server);
};

done_testing;
