package RPG::Traveller::Starmap;
use strict;
use RPG::Dice;
use RPG::Traveller::Starmap::Sector;
use Moose;

# ABSTRACT:  A collection of star map generation tools for the RPG Traveller

has grid => ( is => "rw", isa => "ArrayRef", default => sub { return [] } );
has grid_width  => ( is => "rw", isa => "Int", default => 1 );
has grid_height => ( is => "rw", isa => "Int", default => 1 );

1;

__END__

=pod

=head1 NAME

RPG::Traveller::Starmap - A collection of star map generation tools for the RPG Traveller

=head1 VERSION

version 0.500

=head1 Description

This module encapsulates the generation of starmaps for the Role Playing Game (Mega)Traveller. Generation is done from the sector level down by default. 

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
