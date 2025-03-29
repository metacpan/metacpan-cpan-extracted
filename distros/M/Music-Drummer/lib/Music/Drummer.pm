package Music::Drummer;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Use MIDI::Drummer::Tiny

our $VERSION = '0.6004';

use parent 'MIDI::Drummer::Tiny';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Drummer - Use MIDI::Drummer::Tiny

=head1 VERSION

version 0.6004

=head1 SYNOPSIS

  use Music::Drummer ();

  my $d = Music::Drummer->new(
    # ...
  );
  $d->count_in(1);
  # etc.

=head1 DESCRIPTION

C<Music::Drummer> uses the L<MIDI::Drummer::Tiny> module. It is simply
a module alias with a friendlier, searchable name and description
keywords like B<drum>, B<drums>, and B<drumming>.

=head1 SEE ALSO

L<MIDI::Drummer::Tiny>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
