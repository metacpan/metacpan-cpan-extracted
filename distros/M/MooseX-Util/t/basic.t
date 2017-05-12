use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use MooseX::Util::Meta::Class;

{ package Zombie::Catcher;                              use Moose;       }
{ package Zombie::Catcher::Tools::Machete;              use Moose::Role; }
{ package Zombie::Catcher::Tools::TracyChapmansFastCar; use Moose::Role; }

my $catcher = MooseX::Util::Meta::Class->create_anon_class(
    superclasses => [ 'Zombie::Catcher' ],
    weaken => 0,
    roles => [ qw{
        Zombie::Catcher::Tools::Machete
    } ],
);

# created anon classname like: Zombie::Catcher::__ANON__::SERIAL::42
note $catcher->name;

validate_class $catcher->name => (
    anonymous => 1,
    isa       => [ 'Zombie::Catcher' ],
    does      => [ qw{
        Zombie::Catcher::Tools::Machete
    }],
);

like $catcher->name, qr/^Zombie::Catcher::__ANON__::SERIAL::\d+$/, 'named as expected';

my $fast_catcher = MooseX::Util::Meta::Class->create_anon_class(
    superclasses => [ $catcher->name ],
    weaken => 0,
    roles => [ qw{
        Zombie::Catcher::Tools::TracyChapmansFastCar
    } ],
);

validate_class $fast_catcher->name => (
    anonymous => 1,
    isa => [ $catcher->name ],
    does => [ qw{
        Zombie::Catcher::Tools::TracyChapmansFastCar
    }],
);

like $fast_catcher->name, qr/^Zombie::Catcher::__ANON__::SERIAL::\d+$/, 'named as expected';

done_testing;
