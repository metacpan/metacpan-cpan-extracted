# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'No such class hashref::Perl::Types::Test::Subclass::MySubclasserA_Goodd' >>>

# [[[ HEADER ]]]

package Perl::Types::Test::Subclass::MySubclasserB_Bad_02;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Types::Test::Subclass::MySubclasserA_Good);
use Perl::Types::Test::Subclass::MySubclasserA_Good;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ OO PROPERTIES ]]]
our hashref $properties = { preschool => my string $TYPED_preschool = 'Eager Muskrat', kindergarten => my string $TYPED_kindergarten = 'Eagle Elementary' };

# [[[ SUBROUTINES & OO METHODS ]]]

sub alphabet {
    { my Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $self ) = @ARG;
    $self->{kindergarten} .= '; ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    my Perl::Types::Test::Subclass::MySubclasserA_Good $buddy = Perl::Types::Test::Subclass::MySubclasserA_Good->new();
    my Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $chum  = Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new();
    return $chum;
}

sub brush_paints {
    { my arrayref::Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $self ) = @ARG;
    $self->{kindergarten} .= '; green blue purple';
    my arrayref::Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $friends
        = [ Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new(), Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new(),
        Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new() ];
    return $friends;
}

sub clay {
    { my hashref::Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $self ) = @ARG;
    $self->{kindergarten} .= '; bust';
    my hashref::Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $classmates = {
        'huey'  => Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new(),
        'dewey' => Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new(),
        'louie' => Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new()
    };
    return $classmates;
}

sub seesaw {
    { my arrayref::Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $RETURN_TYPE };
    my arrayref::Perl::Types::Test::Subclass::MySubclasserA_Good $strangers
        = [ Perl::Types::Test::Subclass::MySubclasserA_Good->new(), Perl::Types::Test::Subclass::MySubclasserA_Good->new() ];
    my arrayref::Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $others
        = [ Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new(), Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new() ];
    return $others;
}

sub erector_set {
    { my hashref::Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $RETURN_TYPE };
    my hashref::Perl::Types::Test::Subclass::MySubclasserA_Goodd $teachers = {
        'launchpad' => Perl::Types::Test::Subclass::MySubclasserA_Good->new(),
        'donald'    => Perl::Types::Test::Subclass::MySubclasserA_Good->new()
    };
    my hashref::Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $peers = { 'webbigail' => Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new() };
    return $peers;
}

1;    # end of class
