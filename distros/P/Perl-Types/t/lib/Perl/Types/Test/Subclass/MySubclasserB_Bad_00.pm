# [[[ PREPROCESSOR ]]]
# <<< GENERATE_ERROR: 'ERROR ECOGEAS' >>>
# <<< GENERATE_ERROR: 'P011' >>>
# <<< GENERATE_ERROR: "OO property 'preschool' already declared in parent namespace 'Perl::Types::Test::Subclass::MySubclasserA_Good::'" >>>
# <<< GENERATE_ERROR: 'name masking disallowed' >>>

# [[[ HEADER ]]]
use Perl::Types;

package Perl::Types::Test::Subclass::MySubclasserB_Bad_00;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Types::Test::Subclass::MySubclasserA_Good);
use Perl::Types::Test::Subclass::MySubclasserA_Good;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    preschool    => my string $TYPED_preschool    = 'Eager Muskrat',
    kindergarten => my string $TYPED_kindergarten = 'Eagle Elementary'
};

# [[[ SUBROUTINES & OO METHODS ]]]

sub alphabet {
    { my Perl::Types::Test::Subclass::MySubclasserB_Bad_00::method $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserB_Bad_00 $self ) = @ARG;
    $self->{kindergarten} .= '; ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    my Perl::Types::Test::Subclass::MySubclasserA_Good $buddy = Perl::Types::Test::Subclass::MySubclasserA_Good->new();
    my Perl::Types::Test::Subclass::MySubclasserB_Bad_00 $chum  = Perl::Types::Test::Subclass::MySubclasserB_Bad_00->new();
    return $chum;
}

sub brush_paints {
    { my Perl::Types::Test::Subclass::MySubclasserB_Bad_00_arrayref::method $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserB_Bad_00 $self ) = @ARG;
    $self->{kindergarten} .= '; green blue purple';
    my Perl::Types::Test::Subclass::MySubclasserB_Bad_00_arrayref $friends
        = [ Perl::Types::Test::Subclass::MySubclasserB_Bad_00->new(), Perl::Types::Test::Subclass::MySubclasserB_Bad_00->new(),
        Perl::Types::Test::Subclass::MySubclasserB_Bad_00->new() ];
    return $friends;
}

sub clay {
    { my Perl::Types::Test::Subclass::MySubclasserB_Bad_00_hashref::method $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserB_Bad_00 $self ) = @ARG;
    $self->{kindergarten} .= '; bust';
    my Perl::Types::Test::Subclass::MySubclasserB_Bad_00_hashref $classmates = {
        'huey'  => Perl::Types::Test::Subclass::MySubclasserB_Bad_00->new(),
        'dewey' => Perl::Types::Test::Subclass::MySubclasserB_Bad_00->new(),
        'louie' => Perl::Types::Test::Subclass::MySubclasserB_Bad_00->new()
    };
    return $classmates;
}

sub seesaw {
    { my Perl::Types::Test::Subclass::MySubclasserB_Bad_00_arrayref $RETURN_TYPE };
    my Perl::Types::Test::Subclass::MySubclasserA_Good_arrayref $strangers
        = [ Perl::Types::Test::Subclass::MySubclasserA_Good->new(), Perl::Types::Test::Subclass::MySubclasserA_Good->new() ];
    my Perl::Types::Test::Subclass::MySubclasserB_Bad_00_arrayref $others
        = [ Perl::Types::Test::Subclass::MySubclasserB_Bad_00->new(), Perl::Types::Test::Subclass::MySubclasserB_Bad_00->new() ];
    return $others;
}

sub erector_set {
    { my Perl::Types::Test::Subclass::MySubclasserB_Bad_00_hashref $RETURN_TYPE };
    my Perl::Types::Test::Subclass::MySubclasserA_Good_hashref $teachers
        = { 'launchpad' => Perl::Types::Test::Subclass::MySubclasserA_Good->new(), 'donald' => Perl::Types::Test::Subclass::MySubclasserA_Good->new() };
    my Perl::Types::Test::Subclass::MySubclasserB_Bad_00_hashref $peers = { 'webbigail' => Perl::Types::Test::Subclass::MySubclasserB_Bad_00->new() };
    return $peers;
}

1;    # end of class
