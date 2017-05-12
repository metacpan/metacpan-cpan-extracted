use Test::More tests => 5;


# build the testing class
package Bazzle;
use Storm::Object;
storm_table( 'Bazzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'foo' => ( is => 'rw' );


package main;
use Scalar::Util qw(refaddr);
   
use Storm;
use Storm::LiveObjects;

my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->install_class( 'Bazzle' );

my $lo = $storm->live_objects;
ok $lo, 'retrieved live objects';

# create an oject to test
$storm->insert( Bazzle->new(qw/identifier 1 foo bar/) );


{  # with no scope created, objects should not cache
    my $e1 = $storm->lookup( 'Bazzle', '1' );
    my $e2 = $storm->lookup( 'Bazzle', '1' );
    ok(refaddr $e1 != refaddr $e2, 'lookups out of scope do not cache');
}

my $refaddr;
{ # with a scope created, objects should cache
    my $scope = $lo->new_scope;
    ok($scope, 'new scope created');
    
    my $e1 = $storm->lookup( 'Bazzle', '1' );
    my $e2 = $storm->lookup( 'Bazzle', '1' );
    ok(refaddr $e1 == refaddr $e2, 'lookups within a scope do cache');
    $refaddr = refaddr $e1;
}

  
# objects should not be cached once the scope is destroyed
{
    my $e = $storm->lookup( 'Bazzle', '1' );
    ok($refaddr != refaddr $e, 'object no longer cached once out of scope');
}