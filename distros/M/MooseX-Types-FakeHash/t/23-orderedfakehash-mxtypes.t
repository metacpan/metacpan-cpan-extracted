use strict;
use warnings;

use Test::More 0.96;

{

  package Foo;
  use Moose;
  use MooseX::Types::FakeHash qw( :all );
  use MooseX::Types::Moose qw( :all );

  has str => (
    isa => OrderedFakeHash [Str],
    is => 'rw',
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

is(
  exception {
    my $instance = Foo->new( str => [ [ "Key" => "Value" ] ] );
  },
  undef,
  'str can be an array of length 1'
);

is(
  exception {
    my $instance = Foo->new( str => [ [ "Key" => "Value" ], [ "Key" => "Value" ] ] );
  },
  undef,
  'str can be an array of length 2'
);

is(
  exception {
    my $instance = Foo->new( str => [ [ "Key" => "Value" ], [ "Key" => "Value" ], [ "Key" => "Value" ] ] );
  },
  undef,
  'str can be an array of length 3'
);

is(
  exception {
    my $instance = Foo->new( str => [ [ "Key" => "Value" ], [ "Key" => "Value" ], [ "Key" => "Value" ], [ "Key" => "Value" ], ] );
  },
  undef,
  'str can be an array of length 4'
);

isnt(
  exception {
    my $instance = Foo->new( str => [ [ [] => "Value" ] ] );
  },
  undef,
  'str->[0]->[0] must be a string'
);

isnt(
  exception {
    my $instance = Foo->new( str => [ [ "Key" => [] ] ] );
  },
  undef,
  'str->[0]->[1] must be a string'
);

done_testing;

