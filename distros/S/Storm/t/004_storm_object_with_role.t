


package Foo;
use Storm::Role;

has 'foo' => (
    is => 'rw',
    isa => 'Str',
);


package Bar;
use Storm::Object;

use Test::More;

storm_table( 'Bazzle' );

with 'Foo';

has 'identifier' => (
    is => 'rw',
    isa => 'Str',
    traits => [qw( PrimaryKey )],
);



package main;
use Test::More tests => 1;



is (Bar->meta->get_attribute( 'foo' )->column->sql( Bar->meta->storm_table->name ), 'Bazzle.foo', 'attribute added from role');



