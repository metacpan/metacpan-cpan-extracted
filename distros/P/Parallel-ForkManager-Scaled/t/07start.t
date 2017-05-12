#!/usr/bin/env perl
use strict;
use warnings;
use lib 't';
use PMSTestHelper;

use Test::More;

use Parallel::ForkManager::Scaled;

plan tests => 3;

my $pm = Parallel::ForkManager::Scaled->new(
    hard_min_procs   => 1,
    hard_max_procs   => 20,
    initial_procs    => 1,
    idle_target      => 50,
    update_frequency => 0,
    run_on_update    => sub { my $self = shift; diag("cb: ".$self->stats(shift)); undef },
);
ok(defined $pm, 'constructor');

my $helper = PMSTestHelper->new(idle => 70);
no warnings;
*Parallel::ForkManager::Scaled::get_cpu_stats = sub{$helper};
use warnings;

diag($pm->stats(0));
$pm->start or sleep 1, $pm->finish;
$pm->start or sleep 1, $pm->finish;
ok($pm->max_procs == 10, 'New procs (1)');

$pm->wait_all_children;

$pm->soft_max_procs(5);
$pm->set_max_procs(5);
$helper->idle(20);
$pm->start or $pm->finish;
ok($pm->max_procs == 3, 'New procs (2)');

$pm->wait_all_children;
