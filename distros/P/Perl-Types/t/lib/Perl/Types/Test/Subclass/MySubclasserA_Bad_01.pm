# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'No such class Perl::Types::Test::Subclass::MySubclasserA_Bad_01_arrayref::methodd' >>>

# [[[ HEADER ]]]
use Perl::Types;

package Perl::Types::Test::Subclass::MySubclasserA_Bad_01;
use strict;
use warnings;
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
    { my Perl::Types::Test::Subclass::MySubclasserA_Bad_01::method $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserA_Bad_01 $self ) = @ARG;
    $self->{preschool} .= '; ABCDEFG';
    my Perl::Types::Test::Subclass::MySubclasserA_Bad_01 $chum = Perl::Types::Test::Subclass::MySubclasserA_Bad_01->new();
    return $chum;
}

sub finger_paints {
    { my Perl::Types::Test::Subclass::MySubclasserA_Bad_01_arrayref::methodd $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserA_Bad_01 $self ) = @ARG;
    $self->{preschool} .= '; orange yellow red';
    my Perl::Types::Test::Subclass::MySubclasserA_Bad_01_arrayref $friends
        = [ Perl::Types::Test::Subclass::MySubclasserA_Bad_01->new(), Perl::Types::Test::Subclass::MySubclasserA_Bad_01->new(),
        Perl::Types::Test::Subclass::MySubclasserA_Bad_01->new() ];
    return $friends;
}

sub sand_box {
    { my Perl::Types::Test::Subclass::MySubclasserA_Bad_01_hashref::method $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserA_Bad_01 $self ) = @ARG;
    $self->{preschool} .= '; castle';
    my Perl::Types::Test::Subclass::MySubclasserA_Bad_01_hashref $classmates = {
        'alvin'    => Perl::Types::Test::Subclass::MySubclasserA_Bad_01->new(),
        'simon'    => Perl::Types::Test::Subclass::MySubclasserA_Bad_01->new(),
        'theodore' => Perl::Types::Test::Subclass::MySubclasserA_Bad_01->new()
    };
    return $classmates;
}

sub swings {
    { my Perl::Types::Test::Subclass::MySubclasserA_Bad_01_arrayref $RETURN_TYPE };
    my Perl::Types::Test::Subclass::MySubclasserA_Bad_01_arrayref $others
        = [ Perl::Types::Test::Subclass::MySubclasserA_Bad_01->new(), Perl::Types::Test::Subclass::MySubclasserA_Bad_01->new() ];
    return $others;
}

sub tinker_toys {
    { my Perl::Types::Test::Subclass::MySubclasserA_Bad_01_hashref $RETURN_TYPE };
    my Perl::Types::Test::Subclass::MySubclasserA_Bad_01_hashref $peers = {
        'chip' => Perl::Types::Test::Subclass::MySubclasserA_Bad_01->new(),
        'dale' => Perl::Types::Test::Subclass::MySubclasserA_Bad_01->new()
    };
    return $peers;
}

1;                     # end of class
