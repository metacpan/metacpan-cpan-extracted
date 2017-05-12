use strict;
use warnings;

use Test::More 0.96;

{

  package Foo;
  use Moose;
  use MooseX::Types::FakeHash;

  has str => (
    isa      => 'FakeHash[ Str ]',
    is       => 'rw',
    required => 1,
  );

  __PACKAGE__->meta->make_immutable;
}

use Test::Fatal;

isnt(
  exception {
    my $instance = Foo->new();
  },
  undef,
  'str attribute is required'
);

isnt(
  exception {
    my $instance = Foo->new( str => 'Hello' );
  },
  undef,
  'str is not a string'
);

is(
  exception {
    my $instance = Foo->new( str => [] );
  },
  undef,
  'str can be an empty array'
);

isnt(
  exception {
    my $instance = Foo->new( str => ['foo'] );
  },
  undef,
  'str can not be an array of length 1'
);

is(
  exception {
    my $instance = Foo->new( str => [ 'foo', 'bar' ] );
  },
  undef,
  'str can be an array of length 2'
);

isnt(
  exception {
    my $instance = Foo->new( str => [ 'foo', 'bar', 'baz' ] );
  },
  undef,
  'str can not be an array of length 3'
);

is(
  exception {
    my $instance = Foo->new( str => [ 'foo', 'bar', 'baz', 'quux' ] );
  },
  undef,
  'str can be an array of length 4'
);

isnt(
  exception {
    my $instance = Foo->new( str => [ 'foo', [] ] );
  },
  undef,
  'str->[1] cannot be an empty array'
);

isnt(
  exception {
    my $instance = Foo->new( str => [ 'foo', 'bar', 'quux', [] ] );
  },
  undef,
  'str->[3] cannot be not an empty array'
);

done_testing;

