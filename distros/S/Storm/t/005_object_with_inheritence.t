use Test::More tests => 3;

    
package Foo;
use Storm::Object;
storm_table( 'Foos' );
has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'name' => ( is => 'rw' );

package Foo::Bar;
use Storm::Object;
extends 'Foo';
storm_table( 'FooBars' );
has 'baz' => ( is => 'rw' );
    

package main;
   
use Storm;

my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );

ok (Foo->meta->primary_key, 'Foo primary key set');
ok (Foo::Bar->meta->primary_key, 'Foo::Bar primary key set');
is (Foo::Bar->meta->primary_key, Foo->meta->primary_key, 'Foo key = Foo::Bar key');

$storm->aeolus->install_class( 'Foo' );
$storm->aeolus->install_class( 'Foo::Bar' );

$storm->insert( Foo->new );
$storm->insert( Foo::Bar->new );

#my $foobar = Foo::Bar->new( identifier => 1 );
#ok $foobar->identifier, 'Foo::Bar has identifier';
#
#print Foo->meta->get_attribute_list( 'identifier'), "\n";
#print Foo::Bar->meta->get_attribute_list( 'identifier'), "\n";