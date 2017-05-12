use strict;
use warnings;

use Test::More 0.92 tests => 5;
use Test::Moose;

use lib 't/lib';
use Example;

meta_ok('Example');
does_ok( 'Example', 'MooseX::AttributeIndexes::Provider' );
does_ok( 'Example', 'MooseX::AttributeIndexes::Provider::FromAttributes' );

my $i = new_ok(
  'Example',
  [
    foo_indexed => "hello",
    foo_nothing => "world",
    foo_primary => "bar",
  ]
);

is_deeply( $i->attribute_indexes, { 'foo_indexed' => 'hello', 'foo_primary' => 'bar' } );

