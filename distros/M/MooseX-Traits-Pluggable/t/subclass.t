use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;

{ package t::Foo;
  use Moose;
  with 'MooseX::Traits::Pluggable';

  package t::Bar;
  use Moose;
  extends 't::Foo';

  package t::Trait;
  use Moose::Role;

  sub foo { return 42 };
}

my $instance;
lives_ok {
    $instance = t::Bar->new_with_traits( traits => ['t::Trait'] );
} 'creating instance works ok';

ok $instance->does('t::Trait'), 'instance does trait';
is $instance->foo, 42, 'trait works';
