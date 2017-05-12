use Test::More 'no_plan';

package Foo::Bar;
use Storm::Object;
storm_table( 'FooBars' );

has 'id' => ( is => 'rw', isa => 'Str', traits => [qw( PrimaryKey )] );
has 'name' => ( is => 'rw' );

package Foo::Model;
use Storm::Model;

register 'Foo::Bar';
#register 'Foo::Baz';

package main;

ok ( Foo::Model->registered( 'Foo::Bar' ), 'Foo::Bar registered' );
#ok ( Foo::Model->registered( 'Foo::Baz' ), 'Foo::Baz registered' );