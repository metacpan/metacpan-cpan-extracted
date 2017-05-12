use Test::More 'no_plan';


# build the testing class
package Bazzle;
use Storm::Object;
storm_table( 'Bazzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'foo' => ( is => 'rw', traits => [qw( NoStorm )] );
has 'bar' => ( is => 'rw' );


# run the tests
package main;

use Storm;
my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->install_class( 'Bazzle' );

my $o = Bazzle->new(  foo => 'foo', bar => 'bar' );
$storm->insert( $o );

$o = $storm->lookup( 'Bazzle', 1 );
ok ! $o->foo, 'foo not stored';
