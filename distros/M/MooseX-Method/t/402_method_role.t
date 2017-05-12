use Test::More;

use strict;
use warnings;

plan tests => 2;

{
  package Foo;

  use Moose::Role;
  use MooseX::Method;

  method foo => ();
}

{
  package Bar;

  use Moose;
  use Test::Exception;

  dies_ok { with qw/Foo/ };
}

{
  package Baz;

  use Moose;
  use MooseX::Method;
  use Test::Exception;

  method foo => sub {};

  lives_ok { with qw/Foo/ };
}

