use Test::More tests => 1;



package MyPolicy;
use Storm::Policy;

use DateTime;
use Storm::Test::Types qw( DateTime );

define DateTime, 'DATETIME';


# build the testing class
package Bazzle;
use Storm::Object;
storm_table( 'Bazzle' );

use Storm::Test::Types qw( DateTime );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'date' => ( is => 'rw', isa =>  DateTime );


package main;
use Scalar::Util qw(refaddr);
   
use Storm;
use Storm::LiveObjects;

my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'], policy => 'MyPolicy' );
my $definition = $storm->aeolus->table_definition( 'Bazzle' );
$definition =~ s/\s//sg;

is $definition, "CREATETABLEBazzle(identifierVARCHAR(64)PRIMARYKEY,dateDATETIME);", 'definition set';
