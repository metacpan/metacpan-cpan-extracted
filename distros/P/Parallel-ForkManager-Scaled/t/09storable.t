#!/usr/bin/env perl
use strict;
use warnings;
use lib 't';

use Storable qw( freeze thaw );
use Test::More;
use Data::Dumper;

use Parallel::ForkManager::Scaled;

$Storable::forgive_me = 1;

my $pm = Parallel::ForkManager::Scaled->new(
    hard_min_procs   => 1,
    hard_max_procs   => 20,
    initial_procs    => 1,
    idle_target      => 50,
    update_frequency => 0,
    run_on_update    => sub { my $self = shift; diag("cb: ".$self->stats(shift)); undef },
);

ok(defined $pm, 'constructor');

# Make sure they get built before we freeze and save them
# for later tests
my %save = map { $_ => $pm->$_ } @{$pm->__unstorable};
$save{run_on_update} = $pm->run_on_update;

my $mp = thaw(freeze($pm));
ok(defined $mp, 'Storable freeze/thaw');

ok(!$mp->has_run_on_update, 'cleared run_on_update in thawed object');

ok(! eval "\$mp->_has_$_", "cleared $_ in thawed object")
    for @{$mp->__unstorable};

ok($save{$_} eq $pm->$_, "restored $_ after freeze")
    for ('run_on_update', @{$pm->__unstorable});

done_testing();
