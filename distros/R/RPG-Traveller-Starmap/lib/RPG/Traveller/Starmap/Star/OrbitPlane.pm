package RPG::Traveller::Starmap::Star::OrbitPlane;
use strict;
use Moose;
use feature 'switch';
use Bit::Vector;
use RPG::Traveller::Starmap::Constants qw/ :starsizes :startypes /;

# ABSTRACT:  Encapsulates the behavior of an orbital plane
has 'orbitBitMap' => (
    isa     => "Bit::Vector",
    is      => "rw",
    default => sub {
        return Bit::Vector->new_Enum( 32, '0-31' );
    }
);

has habitableZoneBitmap => (
    isa     => "Bit::Vector",
    is      => "rw",
    default => sub {
        return Bit::Vector->new_Enum( 32, '0-31' );
    }
);

has availableOrbitMask => (
    isa     => "Bit::Vector",
    is      => "rw",
    default => sub {
        return Bit::Vector->new_Enum( 32, '0-31' );
    }
);

has firstOuterZone =>
  ( isa => "Int", is => "rw", default => sub { return 4; } );

sub initialize {
    my ( $type, $size, $spectral ) = @_;
    my $orbital_mask   = undef;
    my $habitable_mask = undef;

    given ($size) {

        # This and Ib are not likely to show up but is listed here
        # for completeness.

        when (Ia) {
            given ($type) {
                when (B) {
                    $orbital_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '8-31' )
                        : Bit::Vector->new_Enum( 32, '7-31' )
                    );
                    $habitable_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '13-13' )
                        : Bit::Vector->new_Enum( 32, '12-12' )
                    );
                }
                when (A) {
                    $orbital_mask   = Bit::Vector->new_Enum( 32, '7-31' );
                    $habitable_mask = Bit::Vector->new_Enum( 32, '12-12' );
                }
                when (F) {
                    $orbital_mask = Bit::Vector->new_Enum( 32, '6-31' );
                    $habitable_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '12' )
                        : Bit::Vector->new_Enum( 32, '11' )
                    );
                }
                when ( [ G, K ] ) {
                    $orbital_mask   = Bit::Vector->new_Enum( 32, '7-31' );
                    $habitable_mask = Bit::Vector->new_Enum( 32, '12' );
                }
                when (M) {
                    $orbital_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '7:31' )
                        : Bit::Vector->new_Enum( 32, '8:31' )
                    );
                    $habitable_mask = Bit::Vector->new_Enum( 32, '12' );

                }
            }
        }
        when (Ib) {
            given ($type) {
                when (B) {
                    $orbital_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '8-31' )
                        : Bit::Vector->new_Enum( 32, '7-31' )
                    );
                    $habitable_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '13-13' )
                        : Bit::Vector->new_Enum( 32, '12-12' )
                    );
                }
                when (A) {
                    $orbital_mask   = Bit::Vector->new_Enum( 32, '7-31' );
                    $habitable_mask = Bit::Vector->new_Enum( 32, '12-12' );
                }
                when (F) {
                    $orbital_mask = Bit::Vector->new_Enum( 32, '6-31' );
                    $habitable_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '12' )
                        : Bit::Vector->new_Enum( 32, '11' )
                    );
                }
                when ( [ G, K ] ) {
                    $orbital_mask   = Bit::Vector->new_Enum( 32, '7-31' );
                    $habitable_mask = Bit::Vector->new_Enum( 32, '12' );
                }
                when (M) {
                    $orbital_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '7:31' )
                        : Bit::Vector->new_Enum( 32, '8:31' )
                    );
                    $habitable_mask = Bit::Vector->new_Enum( 32, '12' );

                }
            }
        }
        when (II) {
            given ($type) {
                when (B) {
                    $orbital_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '7:31' )
                        : Bit::Vector->new_Enum( 32, '5:31' )
                    );
                    $habitable_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '12' )
                        : Bit::Vector->new_Enum( 32, '11' )
                    );
                }
                when (A) {
                    $orbital_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '3:31' )
                        : Bit::Vector->new_Enum( 32, '2:31' )
                    );
                    $habitable_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '9' )
                        : Bit::Vector->new_Enum( 32, '8' )
                    );
                }
                when ( [ F, G ] ) {
                    $orbital_mask   = Bit::Vector->new_Enum( 32, '2:31' );
                    $habitable_mask = Bit::Vector->new_Enum( 32, '8' );
                }
                when (K) {
                    $orbital_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '2-31' )
                        : Bit::Vector->new_Enum( 32, '4-31' )
                    );
                    $habitable_mask = Bit::Vector->new_Enum( 32, '9' );
                }
                when (M) {
                    $orbital_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '4:31' )
                        : Bit::Vector->new_Enum( 32, '6:31' )
                    );
                    $habitable_mask = (
                        $spectral < 5
                        ? Bit::Vector->new_Enum( 32, '10' )
                        : Bit::Vector->new_Enum( 32, '11' )
                    );
                }

            }
        }
    }
}

1;

__END__

=pod

=head1 NAME

RPG::Traveller::Starmap::Star::OrbitPlane - Encapsulates the behavior of an orbital plane

=head1 VERSION

version 0.500

=head1 METHODS

=head2 initialize 

This method calculates the orbits available for population around a given star using the size, type and specral class as parameters for lookup.

=head1 SEE ALSO

=for :list *L<Your::Package>
*L<Your::Module>

=head1 AUTHOR

Peter L. Berghold <peter@berghold.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Peter L. Berghold.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
