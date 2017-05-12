use Test::More 'no_plan';


# build the testing class
package Foo;
use Storm::Object -traits => 'Storm::Meta::Class::Trait::AutoTable';

use Storm::Types qw( StormArrayRef );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );

has 'array' => (
    is => 'rw',
    isa => StormArrayRef,
    default => sub { [ ] },
);

package Bar;
use Storm::Object -traits => 'Storm::Meta::Class::Trait::AutoTable';


has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );

has 'int' => (
    is => 'rw',
    isa => 'Int',
);







# run the tests
package main;

use Storm;
my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->install_class( 'Foo' );
$storm->aeolus->install_class( 'Bar' );

{   # insert and data lookup
    my @bars = map { Bar->new( int => $_ ) } 1..5;
    
    my $foo = Foo->new( array => \@bars );
    $storm->insert( @bars );
    $storm->insert( $foo );
    
    my $sth = $storm->source->dbh->prepare( 'SELECT identifier, array FROM Foo' );
    $sth->execute;
    
    my @data = $sth->fetchrow_array;
    is_deeply \@data, ['1', '[Bar=1,Bar=2,Bar=3,Bar=4,Bar=5]'], 'object data retrieved from database';
}

{
    my $scope = $storm->new_scope;
    my $foo = $storm->lookup( 'Foo', 1 );
    
    for ( 1..5 ) {
        is $foo->array->[$_ - 1]->identifier, $_, 'retrieved array element ' . $_;
    }
    
}
