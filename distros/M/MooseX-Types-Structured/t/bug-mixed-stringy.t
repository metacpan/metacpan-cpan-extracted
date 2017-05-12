use strict;
use warnings;

use Test::More 0.88;

{
  package Test::MooseX::Types::Structured::StringyBug;

  use Moose;
  use MooseX::Types::Moose qw(Str);
  use MooseX::Types::Structured qw(Tuple Dict);
  use Moose::Util::TypeConstraints;

  subtype "TestStringTypes::SubType",
    as Str,
    where { 1 };

  has 'attr1' => (
    is  => 'ro',
    required => 1,
    isa => Dict[
      foo1 => Str,
      foo2 => "Int",
      foo3 => "TestStringTypes::SubType",
    ],
  );

  has 'attr2' => (
    is  => 'ro',
    required => 1,
    isa => Tuple[
      Str,
      "Int",
      "TestStringTypes::SubType",
    ],
  );
}

my %init_args = (
  attr1 => {
    foo1 => 'a',
    foo2 => 2,
    foo3 => 'c',
  },
  attr2 => ['a', 2, 'c'],
);

ok(
  Test::MooseX::Types::Structured::StringyBug->new(%init_args),
  'Made a class with mixed constraint types',
);

done_testing;
