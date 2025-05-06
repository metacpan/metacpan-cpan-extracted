# [[[ HEADER ]]]
use Perl::Types;
package Perl::Types::Test::Subclass::MySubclasserA_Good;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Types::Test);
use Perl::Types::Test;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitAutomaticExportation)  # SYSTEM SPECIAL 14: allow global exports from Config.pm & elsewhere

# [[[ EXPORTS ]]]
use Exporter qw(import);
our @EXPORT = qw(swings tinker_toys);

# [[[ OO PROPERTIES ]]]
our hashref $properties = { preschool => my string $TYPED_preschool = 'Busy Beaver' };

# [[[ SUBROUTINES & OO METHODS ]]]

sub building_blocks {
    { my Perl::Types::Test::Subclass::MySubclasserA_Good::method $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserA_Good $self ) = @ARG;
    $self->{preschool} .= '; ABCDEFG';
    my Perl::Types::Test::Subclass::MySubclasserA_Good $chum = Perl::Types::Test::Subclass::MySubclasserA_Good->new();
    return $chum;
}

sub finger_paints {
    { my Perl::Types::Test::Subclass::MySubclasserA_Good_arrayref::method $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserA_Good $self ) = @ARG;
    $self->{preschool} .= '; orange yellow red';
    my Perl::Types::Test::Subclass::MySubclasserA_Good_arrayref $friends
        = [ Perl::Types::Test::Subclass::MySubclasserA_Good->new(), Perl::Types::Test::Subclass::MySubclasserA_Good->new(),
        Perl::Types::Test::Subclass::MySubclasserA_Good->new() ];
    return $friends;
}

sub sand_box {
    { my Perl::Types::Test::Subclass::MySubclasserA_Good_hashref::method $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserA_Good $self ) = @ARG;
    $self->{preschool} .= '; castle';
    my Perl::Types::Test::Subclass::MySubclasserA_Good_hashref $classmates = {
        'alvin'    => Perl::Types::Test::Subclass::MySubclasserA_Good->new(),
        'simon'    => Perl::Types::Test::Subclass::MySubclasserA_Good->new(),
        'theodore' => Perl::Types::Test::Subclass::MySubclasserA_Good->new()
    };
    return $classmates;
}

sub swings {
    { my Perl::Types::Test::Subclass::MySubclasserA_Good_arrayref $RETURN_TYPE };
    my Perl::Types::Test::Subclass::MySubclasserA_Good_arrayref $others
        = [ Perl::Types::Test::Subclass::MySubclasserA_Good->new(), Perl::Types::Test::Subclass::MySubclasserA_Good->new() ];
    return $others;
}

sub tinker_toys {
    { my Perl::Types::Test::Subclass::MySubclasserA_Good_hashref $RETURN_TYPE };
    my Perl::Types::Test::Subclass::MySubclasserA_Good_hashref $peers
        = { 'chip' => Perl::Types::Test::Subclass::MySubclasserA_Good->new(), 'dale' => Perl::Types::Test::Subclass::MySubclasserA_Good->new() };
    return $peers;
}

1;    # end of class
