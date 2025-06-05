# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'No such class hashref::Perl::Types::Test::Subclass::MySubclasserA_Bad_02d' >>>

# [[[ HEADER ]]]

package Perl::Types::Test::Subclass::MySubclasserA_Bad_02;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Types::Test);
use Perl::Types::Test;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ OO PROPERTIES ]]]
our hashref $properties = { preschool => my string $TYPED_preschool = 'Busy Beaver' };

# [[[ SUBROUTINES & OO METHODS ]]]

sub building_blocks {
    { my Perl::Types::Test::Subclass::MySubclasserA_Bad_02 $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserA_Bad_02 $self ) = @ARG;
    $self->{preschool} .= '; ABCDEFG';
    my Perl::Types::Test::Subclass::MySubclasserA_Bad_02 $chum = Perl::Types::Test::Subclass::MySubclasserA_Bad_02->new();
    return $chum;
}

sub finger_paints {
    { my arrayref::Perl::Types::Test::Subclass::MySubclasserA_Bad_02 $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserA_Bad_02 $self ) = @ARG;
    $self->{preschool} .= '; orange yellow red';
    my arrayref::Perl::Types::Test::Subclass::MySubclasserA_Bad_02 $friends
        = [ Perl::Types::Test::Subclass::MySubclasserA_Bad_02->new(), Perl::Types::Test::Subclass::MySubclasserA_Bad_02->new(),
        Perl::Types::Test::Subclass::MySubclasserA_Bad_02->new() ];
    return $friends;
}

sub sand_box {
    { my hashref::Perl::Types::Test::Subclass::MySubclasserA_Bad_02d $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserA_Bad_02 $self ) = @ARG;
    $self->{preschool} .= '; castle';
    my hashref::Perl::Types::Test::Subclass::MySubclasserA_Bad_02 $classmates = {
        'alvin'    => Perl::Types::Test::Subclass::MySubclasserA_Bad_02->new(),
        'simon'    => Perl::Types::Test::Subclass::MySubclasserA_Bad_02->new(),
        'theodore' => Perl::Types::Test::Subclass::MySubclasserA_Bad_02->new()
    };
    return $classmates;
}

sub swings {
    { my arrayref::Perl::Types::Test::Subclass::MySubclasserA_Bad_02 $RETURN_TYPE };
    my arrayref::Perl::Types::Test::Subclass::MySubclasserA_Bad_02 $others
        = [ Perl::Types::Test::Subclass::MySubclasserA_Bad_02->new(), Perl::Types::Test::Subclass::MySubclasserA_Bad_02->new() ];
    return $others;
}

sub tinker_toys {
    { my hashref::Perl::Types::Test::Subclass::MySubclasserA_Bad_02 $RETURN_TYPE };
    my hashref::Perl::Types::Test::Subclass::MySubclasserA_Bad_02 $peers = {
        'chip' => Perl::Types::Test::Subclass::MySubclasserA_Bad_02->new(),
        'dale' => Perl::Types::Test::Subclass::MySubclasserA_Bad_02->new()
    };
    return $peers;
}

1;                     # end of class
