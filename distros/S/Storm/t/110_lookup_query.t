use Test::More 'no_plan';


# build the testing class
package Bazzle;
use Storm::Object;
storm_table( 'Bazzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'foo' => ( is => 'rw' );
has 'bar' => ( is => 'rw' );
has 'baz' => ( is => 'rw' );


# run the tests
package main;

use Storm;
my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->install_class( 'Bazzle' );

my $query = Storm::Query::Insert->new( $storm, 'Bazzle' );
my $o = Bazzle->new( identifier => 1, foo => 'foo', bar => 'bar', baz => 'baz' );
$query->insert( $o );

$query = Storm::Query::Lookup->new( $storm, 'Bazzle' );
$o = $query->lookup( 1 );
ok $o, 'retrieved object from database';
isa_ok $o, 'Bazzle';

