use Test::More tests => 4;

    
package Foo;
use Storm::Object;
has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'name' => ( is => 'rw' );

package Foo::Bar;
use Storm::Object -traits => 'Storm::Meta::Class::Trait::AutoTable';
extends 'Foo';
has 'baz' => ( is => 'rw' );
    

package main;
   
use Storm;

my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
ok (Foo->meta->primary_key, 'Foo primary key set');
ok (Foo::Bar->meta->primary_key, 'Foo::Bar primary key set');
is (Foo::Bar->meta->primary_key, Foo->meta->primary_key, 'Foo key = Foo::Bar key');
is (Foo::Bar->meta->storm_table->name, 'Bar', 'table name is bar' );

$storm->aeolus->install_class( 'Foo::Bar' );

$storm->insert( Foo::Bar->new );
