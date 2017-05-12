use Test::More tests => 5;

    
package Foo;
use Storm::Object;
storm_table( 'Foos' );
has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'name' => ( is => 'rw', default => 'default_name' );

package Foo::Bar;
use Storm::Object;
extends 'Foo';
storm_table( 'FooBars' );
has '+name' => ( default => 'override_name' );
    

package main;
   
use Storm;

my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );

ok (Foo->meta->primary_key, 'Foo primary key set');
ok (Foo::Bar->meta->primary_key, 'Foo::Bar primary key set');
is (Foo::Bar->meta->primary_key, Foo->meta->primary_key, 'Foo key = Foo::Bar key');

$storm->aeolus->install_class( 'Foo' );
$storm->aeolus->install_class( 'Foo::Bar' );

$storm->insert( my $foo = Foo->new );
$storm->insert( my $foobar = Foo::Bar->new );

is $foo->name, 'default_name', 'foo has default name';
is $foobar->name, 'override_name', 'foobar overrrides name';

#my $foobar = Foo::Bar->new( identifier => 1 );
#ok $foobar->identifier, 'Foo::Bar has identifier';
#
#print Foo->meta->get_attribute_list( 'identifier'), "\n";
#print Foo::Bar->meta->get_attribute_list( 'identifier'), "\n";