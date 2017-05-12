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
my $o1 = Bazzle->new( identifier => 1, foo => 'boo', bar => 'bar', baz => 'baz' );
my $o2 = Bazzle->new( identifier => 2, foo => 'coo', bar => 'car', baz => 'caz' );
my $o3 = Bazzle->new( identifier => 3, foo => 'doo', bar => 'dar', baz => 'daz' );
$query->insert( $o1, $o2, $o3 );

$query = Storm::Query::Select->new( $storm, 'Bazzle' );
ok $query, 'created select query';

my $iter = $query->results;
ok $iter, 'created result iter';

my ( @results ) = $iter->all;
is scalar (@results), 3, 'retrieved objects';




# test schema
__DATA__

CREATE TABLE Bazzle (
    identifier VARCHAR(10) NOT NULL,
    foo VARCHAR(30),
    bar VARCHAR(30),
    baz VARCHAR(30),
    PRIMARY KEY (identifier)
);