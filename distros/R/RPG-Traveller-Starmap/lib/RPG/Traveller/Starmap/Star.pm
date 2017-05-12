package RPG::Traveller::Starmap::Star;
use strict;
use Moose;
use RPG::Traveller::Starmap::Constants qw/ :starsizes :startypes /;
use RPG::Traveller::Starmap::Star::OrbitPlane;
use RPG::Dice;
use Bit::Vector;
use feature 'switch';

# ABSTRACT:  Base class for a star

has size          => ( is => "rw", isa => "Int" );
has type          => ( is => "rw", isa => "Int" );
has spectralClass => ( is => "rw", isa => "Int" );
has orbitPlane    => (
    is  => "rw",
    isa => "RPG::Traveller::Starmap::Star::OrbitPlane"
);
has habitableOrbit => ( is => "rw", isa => "Int" );
has minOrbit       => ( is => "rw", isa => "Int" );
has orbitMap       => ( is => "rw", isa => "Bit::Vector" );

sub getSpectralClass {
    my $self = shift;

    my $d1 = RPG::Dice->new('1d6');
    given ( $d1->roll() ) {
        when ( [ 1, 3, 5 ] ) {
            my $roll = ( $d1->roll() ) + 4;
            while ( $roll == 10 ) {
                $roll = ( $d1->roll() ) + 4;
            }
            $self->spectralClass($roll);
        }
        when ( [ 2, 4, 6 ] ) {
            my $roll = ( $d1->roll() ) - 1;
            while ( $roll == 5 ) {
                $roll = ( $d1->roll() ) - 1;
            }
            $self->spectralClass($roll);

        }
    }
    if (
        (
               ( ( $self->type() == K ) && ( $self->spactralClass() > 4 ) )
            || ( $self->type() == M )
        )
        && ( $self->size() == IV )
      )
    {
        $self->size(V);
    }

    if (
        ( $self->type() == B )
        || (   ( $self->type() == F )
            && ( $self->spectralClass() < 5 ) )
        && ( $self->size() == IV )
      )
    {
        $self->size(V);
    }
}

sub orbitZones {
    my $self = shift;

}

1;

__END__

=pod

=head1 NAME

RPG::Traveller::Starmap::Star - Base class for a star

=head1 VERSION

version 0.500

=head1 SEE ALSO

=for :list *L<perl>

=head1 AUTHOR

Peter L. Berghold <peter@berghold.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Peter L. Berghold.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
