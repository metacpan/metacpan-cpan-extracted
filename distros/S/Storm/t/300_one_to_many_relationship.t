use Test::More tests => 1;

    
# build the testing classes
package Person;
use Storm::Object;
storm_table( 'People' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'name' => ( is => 'rw' );
one_to_many 'pets' => (
    foreign_class => 'Pet',
    match_on => 'caretaker',
    handles => {
       'pets' => 'iter', 
    } 
);



package Pet;
use Storm::Object;
storm_table( 'Pets' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'name' => ( is => 'rw' );
has 'caretaker' => ( is => 'rw', isa => 'Person' );



package main;
   
use Storm;

my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->install_class( 'Person' );
$storm->aeolus->install_class( 'Pet' );


my $person = Person->new( name => 'Marge' );
$storm->insert( $person );

for ('Santa\'s Little Helper', 'Snowball 2') {
    my $pet = Pet->new( name => $_, caretaker => $person );
    $storm->insert( $pet );
}

is scalar( $person->pets->all ), 2, 'pets retrieved';

