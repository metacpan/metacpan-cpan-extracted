use Test::More;

if( ! $ENV{AUTHOR_TEST} ) {
    plan skip_all => 'Tests run for module author only.';
}
else {
    plan tests => 3;
}


# build the testing class
package Bazzle;
use Storm::Object;
storm_table( 'Bazzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'foo' => ( is => 'rw' );


package main;
use Carp qw( confess );
use Storm;

my $storm = Storm->new( source => ['DBI:mysql:gtest:localhost:3306','tester','password'] );
$storm->aeolus->start_fresh;
$storm->aeolus->install_class( 'Bazzle' );


my $txn = Storm::Transaction->new( $storm, sub {
    $storm->insert( Bazzle->new( foo => 'bar' ) );
    $storm->insert( Bazzle->new( foo => 'baz' ) );
    $storm->insert( Bazzle->new( foo => 'buzz' ) );
    confess 'failed transaction';
});

ok $txn, 'created transaction';

eval { $txn->commit };
is scalar ( $storm->select('Bazzle')->results->all ), 0, 'transaction failed';

$txn = Storm::Transaction->new( $storm, sub {
    $storm->insert( Bazzle->new( foo => 'bar' ) );
    $storm->insert( Bazzle->new( foo => 'baz' ) );
    $storm->insert( Bazzle->new( foo => 'buzz' ) );
});

eval { $txn->commit };
is scalar ( $storm->select('Bazzle')->results->all ), 3, 'transaction succeeded';





