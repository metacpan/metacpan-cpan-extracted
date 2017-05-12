#!/usr/bin/env perl
use strict;
use warnings;
use lib 't';
use PMSTestHelper;

use Test::More;

use Parallel::ForkManager::Scaled;

plan tests => 15;

my $pm = Parallel::ForkManager::Scaled->new(
    hard_min_procs => 5,
    hard_max_procs => 20,
    initial_procs  => 10,
    idle_target    => 50,
);
ok(defined $pm, 'constructor');

my $new;

$new = $pm->adjust_up;
ok($new == 15, 'adjust up (1)');
ok($pm->soft_min_procs == 10, 'adjusted soft min (1)');
diag($pm->stats($new));
$pm->set_max_procs($new);

$new = $pm->adjust_down;
ok($new == 12, 'adjust down');
ok($pm->soft_max_procs == 15, 'adjusted soft max (2)');
diag($pm->stats($new));
$pm->set_max_procs($new);

$new = $pm->adjust_up;
ok($new == 13, 'adjust up (2)');
ok($pm->soft_min_procs == 12, 'adjusted soft min (2)');
diag($pm->stats($new));
$pm->set_max_procs($new);

$new = $pm->adjust_down;
ok($new == 12, 'adjust down (2)');
ok($pm->soft_max_procs == 13, 'adjusted soft max (2)');
diag($pm->stats($new));
$pm->set_max_procs($new);

$pm->_stats_pct(PMSTestHelper->new(idle => 10));

$new = $pm->adjust_down;
ok($new == 9, 'adjust down (3)');
ok($pm->soft_max_procs == 12, 'adjusted soft max (3)');
ok($pm->soft_min_procs == 7, 'adjusted soft min (3)');
diag($pm->stats($new));
$pm->set_max_procs($new);

$pm->idle(90);
$pm->set_max_procs($pm->soft_max_procs);
$pm->adjust_soft_max;
ok($pm->soft_max_procs == 15, 'adjusted soft max (4)');
diag($pm->stats(0));

$pm->soft_max_procs($pm->hard_max_procs);
$pm->adjust_soft_max;
ok($pm->soft_max_procs == $pm->hard_max_procs, 'adjusted soft max (5)');
diag($pm->stats(0));

$pm->soft_min_procs($pm->hard_min_procs);
$pm->adjust_soft_min;
ok($pm->soft_min_procs == $pm->hard_min_procs, 'adjusted soft min (4)');
diag($pm->stats(0));
