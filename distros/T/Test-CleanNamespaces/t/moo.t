use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Needs { 'Moo' => '1.000007' };
use Test::Deep;
use Module::Runtime 'require_module';
use Test::CleanNamespaces;

use lib 't/lib';

foreach my $package (qw(MooyDirty))
{
    require_module($package);
    cmp_deeply(
        Test::CleanNamespaces::_remaining_imports($package),
        superhashof({
            map { $_ => ignore } @{ $package->DIRTY },
        }),
        $package . ' has an unclean namespace - found all uncleaned imports',
    );

    ok($package->can($_), "can do $package->$_") foreach @{ $package->CAN };
    ok(!$package->can($_), "cannot do $package->$_") foreach @{ $package->CANT };
}

foreach my $package (qw(MooyClean MooyRole MooyComposer))
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
