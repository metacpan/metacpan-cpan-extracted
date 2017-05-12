package RPG::Traveller::Person;
use strict;
use Moose;
use RPG::Dice;
use RPG::Traveller::Person::Constants qw/ :all /;
our $VERSION = "1.011";

# -------------------------------------------------------------------------
#The Traveller game in all forms is owned by Far Future Enterprises.
#Copyright 1977 - 2008 Far Future Enterprises. Traveller is a registered
#trademark of Far Future Enterprises. The contents of this code is for personal,
#non-commercial use only. Any use of Far Future Enterprise's copyrighted
#material or trademarks anywhere in this code and its resources should not be
#viewed as a challenge to those copyrights or trademarks. For the full FAIR
#USE POLICY please refer to http://www.farfuture.net/FFEFairUsePolicy2008.pdf
# -------------------------------------------------------------------------

# ABSTRACT:  Base class for a family of (Mega)Traveller character generation modules

has 'strength'        => ( is => "rw", isa => "Int" );
has 'dexterity'       => ( is => "rw", isa => "Int" );
has 'endurance'       => ( is => "rw", isa => "Int" );
has 'intelligence'    => ( is => "rw", isa => "Int" );
has 'education'       => ( is => "rw", isa => "Int" );
has 'social_standing' => ( is => "rw", isa => "Int" );
has 'age'             => ( is => "rw", isa => "Int" );
has 'career'          => ( is => "rw", isa => "Int" );
has 'skills'          => ( is => "rw", isa => "HashRef" );

#
# This method will be moved to a utility module

sub initUPP {
    my $self = shift;
    my $d2   = RPG::Dice->new('2d6');
    $self->strength( $d2->roll() );
    $self->dexterity( $d2->roll() );
    $self->endurance( $d2->roll() );
    $self->intelligence( $d2->roll() );
    $self->education( $d2->roll() );
    $self->social_standing( $d2->roll() );
    $self->age(18);

}

sub upp2string {
    my $self = shift;

    return sprintf(
        "%s%s%s%s%s%s  Age: %d",
        int2alpha( $self->strength() ),
        int2alpha( $self->dexterity() ),
        int2alpha( $self->endurance() ),
        int2alpha( $self->intelligence() ),
        int2alpha( $self->education() ),
        int2alpha( $self->social_standing() ),
        $self->age()
    );
}

sub toString {    # This needs to be overloaded in subordinate modules
    my $self = shift;
    return $self->upp2string();
}
1;

__END__

=pod

=head1 NAME

RPG::Traveller::Person - Base class for a family of (Mega)Traveller character generation modules

=head1 VERSION

version 1.020

=head1 SYNOPSIS

     package Some::RPG::Module;
     use RPG::Traveller::Person;
     use Moose;  # Recommended
     # insert code example here
     extendds(RPG::Traveller::Person;
     ... and the rest of your code goes here.

=head1 METHODS

=head2 initUPP

This method intializes the base UWP values and sets the age to 18

=head2 upp2string

This method returns the current UWP and age values as a formatted string

=head2 toString

This method actually gets overloaded by subordinate modules in order.  This is to return the stats on a particular person generated.

=head1 ATTRIBUTES

For each attribute (since we are using L<Moose>) has its own getter/setter methods created during vivication. The list of modules are as folows:

=over 3

=item strength

=item dexterity

=item endurance

=item intelligence

=item education

=item social_standing

=item age

=item career

=item alive

=item enlisted

=item terms

=back

=head1 Traveller RPG Copyright

The Traveller game in all forms is owned by Far Future Enterprises.
Copyright 1977 - 2008 Far Future Enterprises. Traveller is a registered
trademark of Far Future Enterprises. The contents of this code is for personal,
non-commercial use only. Any use of Far Future Enterprise's copyrighted
material or trademarks anywhere in this code and its resources should not be
viewed as a challenge to those copyrights or trademarks. For the full FAIR
USE POLICY please refer to http://www.farfuture.net/FFEFairUsePolicy2008.pdf

=head1 SEE ALSO

=over 4

*L<RPG::Dice>
*L<Moose>
*L<perl>

=back

=head1 AUTHOR

Peter L. Berghold <cpan@berghold.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Peter L. Berghold.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
