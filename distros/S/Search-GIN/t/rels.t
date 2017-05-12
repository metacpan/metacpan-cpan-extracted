use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Search::GIN::Query::Class';
use ok 'Search::GIN::Extract::Class';

{
    package MyGIN;
    use Moose;

    with (
        qw(
            Search::GIN::Core
            Search::GIN::Driver::Hash
            Search::GIN::SelfIDs
        ),
    );

    sub extract_values {
        my ( $self, $obj, @args ) = @_;

        return $self->objects_to_ids(@{ $obj->friends });
    }

    package MyGIN::Query::Friends;
    use Moose;

    with qw(Search::GIN::Query);

    has friends => (
        isa => "ArrayRef[Person]",
        is  => "ro",
        required => 1,
    );

    sub extract_values {
        my ( $self, $gin ) = @_;

        return (
            values => [ $gin->objects_to_ids(@{ $self->friends }) ],
        );
    }

    sub consistent { 1 }

    package Person;
    use Moose;

    has friends => (
        isa => "ArrayRef[Person]",
        is  => "rw",
        default => sub { [] },
    );
}

my @people = map { Person->new } 0 .. 4;

$people[0]->friends([ @people[1,2] ]);

$people[1]->friends([ @people[0,2,4] ]);

$people[2]->friends([ @people[0,1] ]);

$people[4]->friends([ $people[1] ]);

my $gin = MyGIN->new;

$gin->insert(@people);

my $q = MyGIN::Query::Friends->new( friends => [ $people[1] ] );

my $res = $gin->query( $q );

is_deeply(
    [ sort $res->all ],
    [ sort @people[0, 2, 4] ],
    "friends of person 1",
);
