use Test::More tests => 1;



package MyPolicy;
use Storm::Policy;

use Storm::Test::Types qw( DateTime );
define DateTime, 'DATETIME';
    
    
# build the testing class
package Bazzle;
use Storm::Object;
use DateTime::Format::SQLite;
storm_table( 'Bazzle' );

use Storm::Test::Types qw( DateTime );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );

has 'date' => (
    is => 'rw',
    isa =>  DateTime,
    transform => {
        inflate => sub { DateTime::Format::SQLite->parse_datetime($_) },
        deflate => sub { DateTime::Format::SQLite->format_datetime($_) },
    }
);


package main;
use Scalar::Util qw(refaddr);
   
use Storm;
use Storm::LiveObjects;

my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'], policy => 'MyPolicy'  );
$storm->aeolus->install_class( 'Bazzle' );

my $o = Bazzle->new( date => DateTime->now );
$storm->insert( $o );
$o = $storm->lookup( 'Bazzle', $o->identifier );
isa_ok $o->date, 'DateTime', 'inflated date attribute';


