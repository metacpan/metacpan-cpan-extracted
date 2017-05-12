use Test::More 'no_plan';


# build the testing class
package Bazzle;
use Storm::Object;
storm_table( 'Bazzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'foo' => ( is => 'rw' );
has 'bar' => ( is => 'rw' );
has 'baz' => ( is => 'rw' );


# run the tests
package main;

use Storm;
my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->install_class( 'Bazzle' );

my $o = Bazzle->new(  foo => 'foo', bar => 'bar', baz => 'baz' );

my $query = Storm::Query::Insert->new( $storm, 'Bazzle' );
ok $query->insert( $o ), 'query insert return true';
ok $o->identifier, 'object has identifier';


ok $storm->lookup( 'Bazzle', $o->identifier ), 'object looked up by identifier';

