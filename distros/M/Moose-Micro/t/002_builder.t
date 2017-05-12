use strict;
use warnings;
use Test::More 'no_plan';

{
  package Class;

  use Moose::Micro ';foo';

  sub _build_foo { 42 }
}

my $obj = Class->new;
is($obj->foo, 42, 'automatically detected builder');
