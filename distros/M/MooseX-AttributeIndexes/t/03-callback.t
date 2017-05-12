use strict;
use warnings;

use Test::More tests => 5;
use Test::Moose;

use lib 't/lib';
use Example2;

meta_ok('Example2');
does_ok( 'Example2', 'MooseX::AttributeIndexes::Provider' );
does_ok( 'Example2', 'MooseX::AttributeIndexes::Provider::FromAttributes' );

my $i = new_ok(
  'Example2',
  [
    foo_indexed => "hello",
    foo_nothing => "world",
    foo_primary => "bar",
  ]
);

is_deeply( $i->attribute_indexes, { 'foo_indexed' => 'hello2', 'foo_primary' => 'bar2' } );

