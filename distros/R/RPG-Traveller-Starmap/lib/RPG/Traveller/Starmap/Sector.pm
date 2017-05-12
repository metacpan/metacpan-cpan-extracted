package RPG::Traveller::Starmap::Sector;
use strict;
use Moose;

has name  => ( is => "rw", isa => "Str" );
has right => ( is => "rw", isa => "RPG::Traveller::Starmap::Sector" );
has left  => ( is => "rw", isa => "RPG::Traveller::Starmap::Sector" );
has up    => ( is => "rw", isa => "RPG::Traveller::Starmap::Sector" );
has down  => ( is => "rw", isa => "RPG::Traveller::Starmap::Sector" );

# ABSTRACT:  Blah...blah...blah.. tell the author to put something here...

1;

__END__

=pod

=head1 NAME

RPG::Traveller::Starmap::Sector - Blah...blah...blah.. tell the author to put something here...

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
