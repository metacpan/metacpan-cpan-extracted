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

my $o = Bazzle->new( identifier => 1, foo => 'foo', bar => 'bar', baz => 'baz' );

my $query = Storm::Query::Insert->new( $storm, 'Bazzle' );
ok $query->insert( $o ), 'query insert return true';

my $sth = $storm->source->dbh->prepare( 'SELECT identifier, foo, bar, baz FROM Bazzle' );
$sth->execute;

my @data = $sth->fetchrow_array;
is_deeply \@data, [qw/1 foo bar baz/], 'object data retrieved from database';

