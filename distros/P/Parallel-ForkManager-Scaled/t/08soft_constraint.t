#!/usr/bin/env perl
use strict;
use warnings;
use lib 't';

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

$pm->soft_max_procs(22);
ok($pm->soft_max_procs == 20, 'soft_max_trigger');

$pm->soft_min_procs(0);
ok($pm->soft_min_procs == 1, 'soft_min_trigger');
