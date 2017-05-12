use Test::More tests => 15;


package Bazzle;
use Storm::Object;
storm_table( 'Bazzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'foo' => ( is => 'rw' );
has 'bar' => ( is => 'rw' );
has 'baz' => ( is => 'rw' );


package main;
use Storm;
my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->install_class( 'Bazzle' );


# test query creation
isa_ok $storm->delete_query( 'Bazzle' ) , 'Storm::Query::Delete' , 'query';
isa_ok $storm->insert_query( 'Bazzle' ) , 'Storm::Query::Insert' , 'query';
isa_ok $storm->lookup_query( 'Bazzle' ) , 'Storm::Query::Lookup' , 'query';
isa_ok $storm->refresh_query( 'Bazzle' ), 'Storm::Query::Refresh', 'query';
isa_ok $storm->select_query( 'Bazzle' ) , 'Storm::Query::Select' , 'query';
isa_ok $storm->update_query( 'Bazzle' ) , 'Storm::Query::Update' , 'query';



# test the crud methods
my $o1 = Bazzle->new( identifier => 1, foo => 'boo', bar => 'bar', baz => 'baz' );
my $o2 = Bazzle->new( identifier => 2, foo => 'coo', bar => 'car', baz => 'caz' );
my $o3 = Bazzle->new( identifier => 3, foo => 'doo', bar => 'dar', baz => 'daz' );
ok $storm->insert( $o1, $o2, $o3 ), 'insert method returned true';
ok $storm->lookup( 'Bazzle', 1 ), 'lookup successful';
is scalar( ($storm->select('Bazzle')->results->all) ), 3, 'select query returned objects';

my $o2copy = $storm->lookup( 'Bazzle', 2 );
$o2copy->foo( 'moo' );
$o2copy->bar( 'moo' );
$o2copy->baz( 'moo' );
ok $storm->update( $o2copy ), 'update method returned true';

$storm->refresh( $o2 );
is $o2->foo, 'moo', 'refresh method sucessful';

$storm->delete( $o2 );
ok ! $storm->lookup( 'Bazzle', 2 ), 'delete successful';


# create a scope
ok $storm->new_scope, 'created scope';

ok $storm->new_transaction( sub { 1 } ), 'created transaction';

ok $storm->do_transaction( sub { 1 } ), 'performed transaction';