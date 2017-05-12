use Test::More tests => 1;


package MyPolicy;
use Storm::Policy;

use MooseX::Types -declare => [qw( MyDate )];
use MooseX::Types::Moose qw( Str );

subtype MyDate,
   as Str;

define MyDate, 'DATE';



# build the testing class
package Person;
use Storm::Object;
storm_table( 'People' );



use MooseX::Types::Moose qw( Int );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'first_name' => ( is => 'rw' );
has 'last_name' => ( is => 'rw' );
has 'date_of_birth' => ( is => 'rw', isa => &MyPolicy::MyDate );


# run the tests
package main;

use Storm;
my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->install_class( 'Person' );

my @test_info = (
    [qw/Marge  Simpson  /, '1991-01-01'],
    [qw/Maggie Simpson  /, '1992-01-01'],
    [qw/Homer  Simpson  /, '1993-01-01'],
    [qw/Lisa   Simpson  /, '1994-01-01'],
    [qw/Bart   Simpson  /, '1995-01-01'],
    [qw/Ned    Flanders /, '1996-01-01'],
    [qw/Maude  Flanders /, '1997-01-01'],
    [qw/Todd   Flanders /, '1998-01-01'],
    [qw/Rod    Flanders /, '1999-01-01'],
);

# build test objects
my $x = 1;
for (@test_info) {
    my %info; @info{qw/first_name last_name date_of_birth/} = @{$_};
    $info{identifier} = $x++;
    $storm->insert( Person->new(%info) );
}

my $q = $storm->select( 'Person' );
my $func = $q->function('strftime', '%Y', '.date_of_birth');
$q->where( $func , '=', '1999' );

my $result = $q->results->next;
ok ( $result,  'function worked' );


