# [[[ HEADER ]]]
package Perl::Types::Test::Subclass::MySubclasserB_Good;
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
## no critic qw(ProhibitAutomaticExportation)  # SYSTEM SPECIAL 14: allow global exports from Config.pm & elsewhere

# [[[ EXPORTS ]]]
use Exporter qw(import);
our @EXPORT = qw(swings tinker_toys seesaw erector_set);

# [[[ OO PROPERTIES ]]]
our hashref $properties = { kindergarten => my string $TYPED_kindergarten = 'Eagle Elementary' };

# [[[ SUBROUTINES & OO METHODS ]]]

sub alphabet {
    { my Perl::Types::Test::Subclass::MySubclasserB_Good $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserB_Good $self ) = @ARG;
    $self->{kindergarten} .= '; ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    my Perl::Types::Test::Subclass::MySubclasserA_Good $buddy = Perl::Types::Test::Subclass::MySubclasserA_Good->new();
    my Perl::Types::Test::Subclass::MySubclasserB_Good $chum  = Perl::Types::Test::Subclass::MySubclasserB_Good->new();
    return $chum;
}

sub brush_paints {
    { my arrayref::Perl::Types::Test::Subclass::MySubclasserB_Good $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserB_Good $self ) = @ARG;
    $self->{kindergarten} .= '; green blue purple';
    my arrayref::Perl::Types::Test::Subclass::MySubclasserB_Good $friends
        = [ Perl::Types::Test::Subclass::MySubclasserB_Good->new(), Perl::Types::Test::Subclass::MySubclasserB_Good->new(),
        Perl::Types::Test::Subclass::MySubclasserB_Good->new() ];
    return $friends;
}

sub clay {
    { my hashref::Perl::Types::Test::Subclass::MySubclasserB_Good $RETURN_TYPE };
    ( my Perl::Types::Test::Subclass::MySubclasserB_Good $self ) = @ARG;
    $self->{kindergarten} .= '; bust';
    my hashref::Perl::Types::Test::Subclass::MySubclasserB_Good $classmates = {
        'huey'  => Perl::Types::Test::Subclass::MySubclasserB_Good->new(),
        'dewey' => Perl::Types::Test::Subclass::MySubclasserB_Good->new(),
        'louie' => Perl::Types::Test::Subclass::MySubclasserB_Good->new()
    };
    return $classmates;
}

sub seesaw {
    { my arrayref::Perl::Types::Test::Subclass::MySubclasserB_Good $RETURN_TYPE };
    my arrayref::Perl::Types::Test::Subclass::MySubclasserA_Good $strangers
        = [ Perl::Types::Test::Subclass::MySubclasserA_Good->new(), Perl::Types::Test::Subclass::MySubclasserA_Good->new() ];
    my arrayref::Perl::Types::Test::Subclass::MySubclasserB_Good $others
        = [ Perl::Types::Test::Subclass::MySubclasserB_Good->new(), Perl::Types::Test::Subclass::MySubclasserB_Good->new() ];
    return $others;
}

sub erector_set {
    { my hashref::Perl::Types::Test::Subclass::MySubclasserB_Good $RETURN_TYPE };
    my hashref::Perl::Types::Test::Subclass::MySubclasserA_Good $teachers
        = { 'launchpad' => Perl::Types::Test::Subclass::MySubclasserA_Good->new(), 'donald' => Perl::Types::Test::Subclass::MySubclasserA_Good->new() };
    my hashref::Perl::Types::Test::Subclass::MySubclasserB_Good $peers = { 'webbigail' => Perl::Types::Test::Subclass::MySubclasserB_Good->new() };
    return $peers;
}

1;    # end of class
