# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'No such class Perl::Types::Test::Subclass::MySubclasserA_Good_hashrefd' >>>

# [[[ HEADER ]]]
use Perl::Types;

package Perl::Types::Test::Subclass::MySubclasserB_Bad_02;
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
our hashref $properties = { preschool => my string $TYPED_preschool = 'Eager Muskrat', kindergarten => my string $TYPED_kindergarten = 'Eagle Elementary' };

# [[[ SUBROUTINES & OO METHODS ]]]

sub alphabet {
    { my Perl::Types::Test::Subclass::MySubclasserB_Bad_02::method $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $self ) = @ARG;
    $self->{kindergarten} .= '; ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    my Perl::Types::Test::Subclass::MySubclasserA_Good $buddy = Perl::Types::Test::Subclass::MySubclasserA_Good->new();
    my Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $chum  = Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new();
    return $chum;
}

sub brush_paints {
    { my Perl::Types::Test::Subclass::MySubclasserB_Bad_02_arrayref::method $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $self ) = @ARG;
    $self->{kindergarten} .= '; green blue purple';
    my Perl::Types::Test::Subclass::MySubclasserB_Bad_02_arrayref $friends
        = [ Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new(), Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new(),
        Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new() ];
    return $friends;
}

sub clay {
    { my Perl::Types::Test::Subclass::MySubclasserB_Bad_02_hashref::method $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserB_Bad_02 $self ) = @ARG;
    $self->{kindergarten} .= '; bust';
    my Perl::Types::Test::Subclass::MySubclasserB_Bad_02_hashref $classmates = {
        'huey'  => Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new(),
        'dewey' => Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new(),
        'louie' => Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new()
    };
    return $classmates;
}

sub seesaw {
    { my Perl::Types::Test::Subclass::MySubclasserB_Bad_02_arrayref $RETURN_TYPE };
    my Perl::Types::Test::Subclass::MySubclasserA_Good_arrayref $strangers
        = [ Perl::Types::Test::Subclass::MySubclasserA_Good->new(), Perl::Types::Test::Subclass::MySubclasserA_Good->new() ];
    my Perl::Types::Test::Subclass::MySubclasserB_Bad_02_arrayref $others
        = [ Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new(), Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new() ];
    return $others;
}

sub erector_set {
    { my Perl::Types::Test::Subclass::MySubclasserB_Bad_02_hashref $RETURN_TYPE };
    my Perl::Types::Test::Subclass::MySubclasserA_Good_hashrefd $teachers = {
        'launchpad' => Perl::Types::Test::Subclass::MySubclasserA_Good->new(),
        'donald'    => Perl::Types::Test::Subclass::MySubclasserA_Good->new()
    };
    my Perl::Types::Test::Subclass::MySubclasserB_Bad_02_hashref $peers = { 'webbigail' => Perl::Types::Test::Subclass::MySubclasserB_Bad_02->new() };
    return $peers;
}

1;    # end of class
