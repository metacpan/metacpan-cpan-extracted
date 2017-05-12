use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Module::Runtime 'require_module';
use Test::CleanNamespaces;

use lib 't/lib';

{
    my $package = 'Overloader';

    require_module($package);
    cmp_deeply(
        Test::CleanNamespaces::_remaining_imports($package),
        {},
        $package . ' has a clean namespace',
    );

    my $obj = $package->new(val => 42);

    is("$obj", '42', 'string overload works');
    is($obj + 1, 43, 'numeric overload works');

    ok($package->can($_), "can do $package->$_") foreach @{ $package->CAN };
    ok(!$package->can($_), "cannot do $package->$_") foreach @{ $package->CANT };
}

done_testing;
