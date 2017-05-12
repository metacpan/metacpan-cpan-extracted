use Test::More tests => 1;


# build the testing class
package Person;
use Storm::Object;
storm_table( 'People' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'position' => ( is => 'rw', isa => 'Position' );
has 'name' => ( is => 'rw' );

package Position;
use Storm::Object;
storm_table( 'Positions' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'title' => ( is => 'rw' );





# run the tests
package main;

use Storm;
my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->install_class( 'Person' );
$storm->aeolus->install_class( 'Position' );

my $person = Person->new( name => 'Homer' );
$storm->insert( $person );

my $position = Position->new( title => 'Owner' );
$storm->insert( $position );

$person = Person->new( name => 'Ned', position => $position );
$storm->insert( $person );


my $q = $storm->select('Person')->where('.position.title', '=', 'Owner');
print $q->_sql, "\n";

my @results = $q->results->all;
ok scalar @results == 1 && $results[0]->name eq 'Ned', 'select successful';


