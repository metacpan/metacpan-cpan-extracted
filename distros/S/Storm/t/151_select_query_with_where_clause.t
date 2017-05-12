use Test::More tests => 6;


# build the testing class
package Person;
use Storm::Object;
storm_table( 'People' );

use MooseX::Types::Moose qw( Int );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'first_name' => ( is => 'rw' );
has 'last_name' => ( is => 'rw' );
has 'age' => ( is => 'rw', isa => Int );


# run the tests
package main;

use Storm;
my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->install_class( 'Person' );

my @test_info = (
    [qw/Marge  Simpson  38/],
    [qw/Maggie Simpson   1/],
    [qw/Homer  Simpson  40/],
    [qw/Lisa   Simpson   8/],
    [qw/Bart   Simpson  10/],
    [qw/Ned    Flanders 43/],
    [qw/Maude  Flanders 28/],
    [qw/Todd   Flanders  9/],
    [qw/Rod    Flanders  9/],
);

# build test objects
my $x = 1;
for (@test_info) {
    my %info; @info{qw/first_name last_name age/} = @{$_};
    $info{identifier} = $x++;
    $storm->insert( Person->new(%info) );
}

{ # like
    my $q = $storm->select( 'Person' );
    $q->where( '.last_name', 'like', '%anders' );
    my @results = $q->results->all;
    is scalar (@results), 4, 'like successful';
}

{ # not like
    my $q = $storm->select( 'Person' );
    $q->where( '.last_name', 'not_like', '%anders');
    my @results = $q->results->all;
    is scalar (@results), 5, 'not like successful';
}

{ # between
    my $q = $storm->select( 'Person' );
    $q->where( '.age', 'between', 1, 10);
    my @results = $q->results->all;
    is scalar (@results), 5, 'between successful';
}

{ # in
    my $q = $storm->select( 'Person' );
    $q->where( '.last_name', 'in', 'Simpson', 'Flanders');
    my @results = $q->results->all;
    is scalar (@results), 9, 'in successful';
}


{ # not in
    my $q = $storm->select( 'Person' );
    $q->where( '.first_name', 'not in', qw/Lisa Bart Rod Todd/);
    my @results = $q->results->all;
    is scalar (@results), 5, 'not in successful';
}

{ # with place holder
    my $q = $storm->select( 'Person' );
    $q->where( '.age', '=', '?' );
    my @results = $q->results( 28 )->all;
    is scalar (@results), 1, 'place holder successful';
}

