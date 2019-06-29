package Term::Caca::Bitmap;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: an OO-interface to caca_bitmap
$Term::Caca::Bitmap::VERSION = '3.1.0';
use strict;
use warnings;
use Term::Caca;

sub new {
  my ($class, $bpp, $w, $h, $pitch, $rmask, $gmask, $bmask, $amask) = @_;
  my $self = Term::Caca::_create_bitmap($bpp, $w, $h, $pitch, $rmask, $gmask, $bmask, $amask);
  return bless($self => $class);
}

sub set_palette {
  my ($self, $red, $green, $blue, $alpha) = @_;
  return Term::Caca::_set_bitmap_palette($self, $red, $green, $blue, $alpha);
}

sub draw {
  my ($self, $x1, $y1, $x2, $y2, $pixels) = @_;
  return Term::Caca::_draw_bitmap_tied($x1, $y1, $x2, $y2, $self, $pixels);
}

sub DESTROY {
  my ($self) = @_;
  Term::Caca::_free_bitmap($self);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Term::Caca::Bitmap - an OO-interface to caca_bitmap

=head1 VERSION

version 3.1.0

=head1 SYNOPSIS

Basic usage

  use Term::Caca::Bitmap;
  my $thing = Term::Caca::Bitmap->new();

=head1 DESCRIPTION

A L<Term::Caca::Bitmap|Term::Caca::Bitmap> object represents
a surface that pixels can be drawn on.

=head1 METHODS

=head2 new

...

B<Example>:

=head2 set_palette

...

B<Example>:

=head2 draw

...

B<Example>:

=head2 DESTROY

...

B<Example>:

=head1 CLASS VARIABLES

cvars

=head1 DIAGNOSTICS

no errors

=head1 AUTHOR

John BEPPU E<lt>beppu@cpan.orgE<gt>

=head1 SEE ALSO

perl(1)

=head1 AUTHORS

=over 4

=item *

John Beppu <beppu@cpan.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019, 2018, 2013, 2011 by John Beppu.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

__END__




# $Id: pmpod,v 1.3 2004/10/28 07:37:32 beppu Exp $
