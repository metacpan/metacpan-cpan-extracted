use strict;
use warnings;

use Test::More 0.88;
use Test::Needs { 'Role::Tiny' => '1.003000' };
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Module::Runtime 'require_module';
use Test::CleanNamespaces;

use lib 't/lib';

foreach my $package (qw(Clean Role Composer))
{
    require_module($package);
    cmp_deeply(
        Test::CleanNamespaces::_remaining_imports($package),
        {},
        $package . ' has a clean namespace',
    );

    ok($package->can($_), "can do $package->$_") foreach @{ $package->CAN };
    ok(!$package->can($_), "cannot do $package->$_") foreach @{ $package->CANT };
}

ok(!exists($INC{'Class/MOP.pm'}), 'Class::MOP has not been loaded');
ok(!exists($INC{'Moose.pm'}), 'Moose has not been loaded');
ok(!exists($INC{'Mouse.pm'}), 'Mouse has not been loaded');

done_testing;
