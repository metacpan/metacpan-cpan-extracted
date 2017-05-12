#!/usr/bin/env perl
use strict;
use warnings;
use lib 't';
use PMSTestHelper;

use Test::More;

use Parallel::ForkManager::Scaled;

plan tests => 2;

my $pm = Parallel::ForkManager::Scaled->new(
    hard_min_procs   => 1,
    hard_max_procs   => 5,
    update_frequency => 0,
    run_on_update    => sub { diag("in callback"); shift->set_max_procs(4) }
);
ok(defined $pm, 'constructor');

my $helper = PMSTestHelper->new(idle => 70);
no warnings;
*Parallel::ForkManager::Scaled::get_cpu_stats = sub{$helper};
use warnings;

diag($pm->stats(0));
$pm->start or $pm->finish;
diag($pm->stats(0));
ok($pm->max_procs == 4, 'New procs (1)');

$pm->wait_all_children;
