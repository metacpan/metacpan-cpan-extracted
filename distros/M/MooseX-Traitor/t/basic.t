use strict;
use warnings;

{ package TestClass; use Moose; with 'MooseX::Traitor' }
{ package TestRole;  use Moose::Role                   }

use Test::More;
use Test::Moose::More;

# we don't need much here as with_traits() is tested in MooseX::Util's tests

validate_class TestClass => (
    does    => [ qw{ MooseX::Traitor } ],
    methods => [ qw{ with_traits     } ],
);

my $new = TestClass->with_traits('TestRole');

validate_class $new => (
    isa       => [ qw{ TestClass } ],
    does      => [ qw{ TestRole } ],
    anonymous => 1,
);

like $new => qr/^TestClass::__ANON__::SERIAL::\d+$/,
    'anon class name looks correct';

done_testing;
