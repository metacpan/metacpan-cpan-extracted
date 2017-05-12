use strict;
use warnings;

use Test::More;
use Test::Moose::More;

#use MooseX::Util::Meta::Class;
use MooseX::Util 'with_traits';

{ package Zombie::Catcher;                              use Moose;       }
{ package Zombie::Catcher::Tools::Machete;              use Moose::Role; }
{ package Zombie::Catcher::Tools::TracyChapmansFastCar; use Moose::Role; }

my $catcher = with_traits(
    'Zombie::Catcher' => qw{
        Zombie::Catcher::Tools::Machete
    },
);

# created anon classname like: Zombie::Catcher::__ANON__::SERIAL::42
note $catcher;

validate_class $catcher => (
    anonymous => 1,
    isa       => [ 'Zombie::Catcher' ],
    does      => [ qw{
        Zombie::Catcher::Tools::Machete
    }],
);

like $catcher, qr/^Zombie::Catcher::__ANON__::SERIAL::\d+$/, 'named as expected';

my $fast_catcher = with_traits(
    $catcher => qw{
        Zombie::Catcher::Tools::TracyChapmansFastCar
    },
);

validate_class $fast_catcher => (
    anonymous => 1,
    isa => [ $catcher ],
    does => [ qw{
        Zombie::Catcher::Tools::TracyChapmansFastCar
    }],
);

like $fast_catcher, qr/^Zombie::Catcher::__ANON__::SERIAL::\d+$/, 'named as expected';

done_testing;
