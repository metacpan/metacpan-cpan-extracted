package RPG::Traveller::Starmap::Subsector;
use strict;
use RPG::Traveller::Starmap::Constants qw/ :densities /;
use RPG::Traveller::Starmap::Parsec;
use Moose;
use RPG::Dice;

# ABSTRACT:  Encapsulates a (Mega)Traveller subsector
has posit   => ( is => "rw", isa => "Str" );
has name    => ( is => "rw", isa => "Str" );
has density => ( is => "rw", isa => "Int", default => NORMAL );

my $positTable = [

    #    A B C D
    { miny => 1, minx => 1 },
    { miny => 1, minx => 9 },
    { miny => 1, minx => 17 },
    { miny => 1, minx => 25 },

    #   E F G H
    { miny => 11, minx => 1 },
    { miny => 11, minx => 9 },
    { miny => 11, minx => 17 },
    { miny => 11, minx => 25 },

    #   I J K L
    { miny => 21, minx => 1 },
    { miny => 21, minx => 9 },
    { miny => 21, minx => 17 },
    { miny => 21, minx => 25 },

    #   M N O P
    { miny => 31, minx => 1 },
    { miny => 31, minx => 9 },
    { miny => 31, minx => 17 },
    { miny => 31, minx => 25 },

    #   <----- End of Table
];

my $genTable = [
    {},
    { dice => '2d6', min => 12 },
    { dice => '1d6', min => 6 },
    { dice => '1d6', min => 5 },
    { dice => '1d6', min => 4 },
    { dice => '1d6', min => 3 }
];

sub generate {
    my $self = shift;
    my ( $miny, $minx ) = ();
    if ( $self->posit() ) {
        my $p = $self->posit();
        $p =~ tr/A-Z/a-z/;
        my $offset = $p - 'a';
        my $r      = $positTable->[$offset];
        ( $miny, $minx ) = ( $r->{miny}, $r->{minx} );
    }
    else {
        $self->posit('a');
        ( $miny, $minx ) = ( 1, 1 );
    }

    my ( $dice, $min ) = (
        $genTable->[ $self->density ]->{dice},
        $genTable->[ $self->density ]->{min}
    );
    my $d = new RPG::Dice($dice);

    my $parsecGrid = [];
    $parsecGrid->[$_] = [] foreach ( 0 .. 9 );

    foreach my $y ( $miny .. ( $miny + 9 ) ) {
        foreach my $x ( $minx .. ( $minx + 7 ) ) {
            if ( $d->rol() >= $min ) {
                my $parsec = new RPG::Traveller::Starmap::Parsec();

                # Flesh out parsec here...
                $parsecGrid->[$y]->[$x] = $parsec;
            }
            else {
                $parsecGrid->[$y]->[$x] = undef;
            }
        }
    }

}

1;

__END__

=pod

=head1 NAME

RPG::Traveller::Starmap::Subsector - Encapsulates a (Mega)Traveller subsector

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    use RPG::Traveller::Starmap::Constants qw/ :densities / ;
    use RPG::Traveller::Starmap::Subsector;

    my $subsector = new RPG::Traveller::Starmap::Subsector;
    $subsector->density(RIFT);  # from RPG::Traveller::Starmap::Constants
    $subsector->posit('C');
    $subsector->name('Regina');
    $subsector->generate();

=head1 METHODS

=head2 name 

A getter/setter method for the name attribute.

=head2 posit

A getter/setter method for the posit attribute.  Posit is the "letter" representing the position within a sector for this subsector.

=head2 density

A getter/setter method for the density of the subsector.

=head2 generate

This actually performs the generation of the subsector by checking to see where each parsec within the subsector is occupied based on the C<density> parameter.

=head1 SEE ALSO

=for :list *L<Moose>
*L<perl>
*L<RPG::Dice>

=head1 AUTHOR

Peter L. Berghold <peter@berghold.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Peter L. Berghold.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
