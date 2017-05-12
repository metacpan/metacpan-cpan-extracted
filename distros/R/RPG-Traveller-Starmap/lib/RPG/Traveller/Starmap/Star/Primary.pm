package RPG::Traveller::Starmap::Star::Primary;
use strict;
use Moose;
use RPG::Traveller::Starmap::Star;
use RPG::Traveller::Starmap::Constants qw/ :starsizes :startypes /;
use RPG::Dice;
use feature 'switch';

extends 'RPG::Traveller::Starmap::Star';

# ABSTRACT:  Encapsulates the behavior of a primary star

sub generate {
    my $self = shift;
    my $d1   = RPG::Dice->new('1d6');
    my $d2   = RPG::Dice->new('2d6');

    given ( $d2->roll() ) {
        when (2) {
            $self->type(A);
        }
        when ( [ 3 .. 7 ] ) {
            $self->type(M);
        }
        when (8) {
            $self->type(K);
        }
        when (9) {
            $self->type(G);
        }
        when ( [ 10 .. 12 ] ) {
            $self->type(F);
        }
    }

    given ( $d2->roll() ) {
        when (2) {
            $self->size(II);
        }
        when (3) {
            $self->size(III);
        }
        when (4) {
            $self->size(IV);
        }
        when ( [ 5 .. 10 ] ) {
            $self->size(V);
        }
        when (11) {
            $self->size(VI);
        }
        when (12) {
            $self->size(D);
        }
    }

    $self->getSpectralClass();

}

1;

__END__

=pod

=head1 NAME

RPG::Traveller::Starmap::Star::Primary - Encapsulates the behavior of a primary star

=head1 VERSION

version 0.500

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
