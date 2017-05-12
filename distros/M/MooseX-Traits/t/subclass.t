use strict;
use warnings;
use Test::More tests => 3;
use Test::Fatal;

{ package Foo;
  use Moose;
  with 'MooseX::Traits';

  package Bar;
  use Moose;
  extends 'Foo';

  package Trait;
  use Moose::Role;

  sub foo { return 42 };
}

my $instance;
is
    exception {
        $instance = Bar->new_with_traits( traits => ['Trait'] );
    },
    undef,
    'creating instance works ok';

ok $instance->does('Trait'), 'instance does trait';
is $instance->foo, 42, 'trait works';
