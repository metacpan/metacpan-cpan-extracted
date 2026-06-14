#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp 'tempdir';
use File::Spec;
use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

# ═══════════════════════════════════════════════════════════════════════════
# Direct cycle: CycleA → CycleB → CycleA
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Direct cycle A→B→A detected during Fondation load' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app     = create_test_app($tempdir);

    eval {
        $app->plugin('Fondation' => {
            dependencies => ['Fondation::CycleA'],
        });
        1;
    };

    ok($@, 'Cycle detection fired during Fondation plugin() call');
    like($@, qr/cycle/i, 'Error message mentions "cycle"');
    like($@, qr/CycleA|CycleB/i, 'Error message names at least one plugin involved');
};

# ═══════════════════════════════════════════════════════════════════════════
# Indirect cycle: Loading CycleB (same cycle, different entry point)
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Indirect cycle detected from different entry point (B→A→B)' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app     = create_test_app($tempdir);

    eval {
        $app->plugin('Fondation' => {
            dependencies => ['Fondation::CycleB'],
        });
        1;
    };

    ok($@, 'Cycle detected when entering via CycleB');
    like($@, qr/cycle/i, 'Error message mentions cycle');
};

# ═══════════════════════════════════════════════════════════════════════════
# No false positive: linear deps still load fine
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Linear dependencies still load without cycle false positives' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $app     = create_test_app($tempdir);

    eval {
        $app->plugin('Fondation' => {
            dependencies => ['Fondation::User'],
        });
        1;
    };

    ok(!$@, 'No error for linear dependencies')
        or diag "Unexpected error: $@";

    my $manager = $app->manager;
    ok($manager->registry->{'Mojolicious::Plugin::Fondation::User'},
       'User plugin loaded correctly');
};

done_testing();
