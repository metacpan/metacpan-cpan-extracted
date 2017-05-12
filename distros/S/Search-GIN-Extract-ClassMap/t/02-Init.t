
use strict;
use warnings;

use Test::More 0.96 tests                    => 6;
use aliased 'Search::GIN::Extract::ClassMap' => 'CM';

my $map = new_ok( CM,
  [
    extract      => {},
    extract_isa  => {},
    extract_does => {},
  ]
);

$map = new_ok( CM,
  [
    extract      => { baz => [qw( asd )], },
    extract_isa  => { foo => [qw( asd )], },
    extract_does => { bar => [qw( asd )], },
  ]
);

{

  package baz;
  use Moose;

  has 'attr' => ( isa => "Str", is => "rw", default => "world" );

  sub asd {
    return "hello";
  }
}

$map = new_ok( CM, [ extract => { baz => [qw( asd attr )] } ] );

is_deeply( [ sort $map->extract_values( baz->new() ) ], ['attr:world'] );

$map = new_ok( CM,
  [
    extract => {
      baz => sub {
        my ($self) = @_;
        return { "foo" => $self->asd };
      },
    },
    extract_isa => { baz => [qw( asd attr )], }
  ]
);

is_deeply( [ sort $map->extract_values( baz->new() ) ], [ sort ( 'attr:world', 'foo:hello', ) ] );

