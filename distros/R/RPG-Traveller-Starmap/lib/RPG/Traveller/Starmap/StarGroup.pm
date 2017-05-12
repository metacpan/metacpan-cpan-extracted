package RPG::Traveller::Starmap::StarGroup;
use strict;
use Moose;
use RPG::Traveller::Starmap::Constants qw/ :sgnature /;
use RPG::Traveller::Starmap::Star::Primary;
use RPG::Traveller::Starmap::Star::Companion;

use RPG::Dice;

has nature => ( is => "rw", isa => "Int" );
has primaryStar =>
  ( is => "rw", isa => "RPG::Traveller::Starmap::Star::Primary" );
has companions => ( is => "rw", isa => "ArrayRef" );

# ABSTRACT:  Blah...blah...blah.. tell the author to put something here...

my @natTable = ();
$natTable[$_] = undef  foreach ( 0 .. 1 );
$natTable[$_] = SOLO   foreach ( 2 .. 7 );
$natTable[$_] = BINARY foreach ( 8 .. 11 );
$natTable[12] = TRINARY;

sub generate {
    my $self = shift;

    my $d   = new RPG::Dice('2d6');
    my $nat = $natTable[ $d->roll() ];

    $self->nature($nat);

    my @companions = ();
    foreach my $i ( 1 .. $nat ) {
        if ( $nat > SOLO ) {
            $companions[ $i - 2 ] = new RPG::Traveller::Star::Companion();
        }
        else {
            $self->primaryStar( new RPG::Traveller::Star::Primary() );
        }
    }
    $self->primaryStar->generate();
    if ( $nat > SOLO ) {
        foreach my $i ( 0 .. $#companions ) {
            $companions[$i]->generate( $self->primaryStar() );
        }
    }
}

1;

__END__

=pod

=head1 NAME

RPG::Traveller::Starmap::StarGroup - Blah...blah...blah.. tell the author to put something here...

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
