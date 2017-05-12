use strict;
use warnings;

use Test::More 0.96;

{

  package Foo;
  use Moose;
  use MooseX::Types::FakeHash;

  has str => (
    isa      => 'FakeHash[ ArrayRef[Any] ]',
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
    my $instance = Foo->new( str => [ 'foo', [] ] );
  },
  undef,
  'str can be an array of length 2'
);

isnt(
  exception {
    my $instance = Foo->new( str => [ 'foo', [], 'baz' ] );
  },
  undef,
  'str can not be an array of length 3'
);

is(
  exception {
    my $instance = Foo->new( str => [ 'foo', [], 'baz', [] ] );
  },
  undef,
  'str can be an array of length 4'
);

is(
  exception {
    my $instance = Foo->new( str => [ 'foo', [] ] );
  },
  undef,
  'str->[1] can be an empty array'
);

isnt(
  exception {
    my $instance = Foo->new( str => [ 'foo', 'bar' ] );
  },
  undef,
  'str->[1] cannot be a string'
);

is(
  exception {
    my $instance = Foo->new( str => [ 'foo', [], 'baz', [] ] );
  },
  undef,
  'str->[3] can be an empty array'
);

isnt(
  exception {
    my $instance = Foo->new( str => [ 'foo', [], 'baz', 'quux' ] );
  },
  undef,
  'str->[3] cannot be a string'
);

done_testing;

