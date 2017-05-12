#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Parallel::ForkManager::Scaled;

plan tests => 23;

my $pm = Parallel::ForkManager::Scaled->new;
ok(defined $pm, 'constructor with no args');

ok($pm->initial_procs > 0, 'initial procs');
ok($pm->max_procs == $pm->initial_procs, 'max procs');

ok($pm->hard_min_procs > 0, 'hard minimum procs');
ok($pm->hard_max_procs >= $pm->hard_min_procs, 'hard maximum procs');
ok($pm->soft_min_procs >= $pm->hard_min_procs, 'soft minimum procs');
ok($pm->soft_max_procs <= $pm->hard_max_procs, 'soft maximum procs 1');
ok($pm->soft_max_procs >= $pm->soft_min_procs, 'soft maximum procs 2');

ok($pm->update_frequency > 0, 'update frequency');


$pm = Parallel::ForkManager::Scaled->new(
    hard_max_procs => 12,
    hard_min_procs => 4,
    soft_max_procs => 13,
    soft_min_procs => 3,
    initial_procs  => 1,
);
ok(defined $pm, 'constructor 2');

ok($pm->soft_min_procs == $pm->hard_min_procs, 'soft_min_procs == hard_min_procs');
ok($pm->soft_max_procs == $pm->hard_max_procs, 'soft_max_procs == hard_max_procs');
ok($pm->max_procs  == $pm->soft_min_procs, 'max_procs == soft_min_procs');


$pm = Parallel::ForkManager::Scaled->new(
    hard_max_procs => 12,
    hard_min_procs => 4,
    soft_max_procs => 13,
    soft_min_procs => 3,
    initial_procs  => 15,
);
ok(defined $pm, 'constructor 3');
ok($pm->max_procs  == $pm->soft_max_procs, 'max_procs == soft_max_procs');


$pm = Parallel::ForkManager::Scaled->new(
    hard_max_procs => 12,
    hard_min_procs => 4,
    soft_max_procs => 10,
    soft_min_procs => 5,
    initial_procs  => 8,
);
ok(defined $pm, 'constructor 4');
ok($pm->soft_min_procs == 5,  'soft_min_procs');
ok($pm->soft_max_procs == 10, 'soft_max_procs');
ok($pm->max_procs == $pm->initial_procs, 'max_procs == initial_procs');


$pm = Parallel::ForkManager::Scaled->new(
    hard_max_procs => 12,
    hard_min_procs => 4,
    soft_max_procs => 10,
    soft_min_procs => 5,
    initial_procs  => 0,
);
ok(defined $pm, 'constructor 5');
ok($pm->max_procs == $pm->soft_min_procs, 'max_procs == soft_min_procs (2)');


$pm = Parallel::ForkManager::Scaled->new(
    hard_max_procs => 12,
    hard_min_procs => 4,
    soft_max_procs => 10,
    soft_min_procs => 5,
    initial_procs  => 20,
);
ok(defined $pm, 'constructor 6');
ok($pm->max_procs == $pm->soft_max_procs, 'max_procs == soft_max_procs (2)');
