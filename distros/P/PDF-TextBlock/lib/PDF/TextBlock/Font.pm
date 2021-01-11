package PDF::TextBlock::Font;

use strict;
use warnings;
use Class::Accessor::Fast;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( pdf font fillcolor size ));

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

our $VERSION = '0.04';

=head1 NAME

PDF::TextBlock::Font - A font object to override the defaults PDF::TextBlock uses

=head1 SYNOPSIS

  TODO  add from t/*

=head1 DESCRIPTION

You can hand PDF::TextBlock objects from this class whenever you want to override
the font defaults.

=head1 METHODS

=head2 apply_defaults

Applies defaults for you wherever you didn't explicitly set a different value.

=cut

sub apply_defaults {
   my ($self) = @_;
   die "pdf attribute (your PDF::API object) required" unless $self->pdf;
   my %defaults = (
      # font is a PDF::API2::Resource::Font::CoreFont (or PDF::Builder)
      font      => $self->pdf->corefont( 'Helvetica', -encoding => 'latin1' ),
      fillcolor => 'black',
      size      => 10 / pt,
   );
   foreach my $att (keys %defaults) {
      $self->$att($defaults{$att}) unless defined $self->$att;
   }

   #my %fonts = (
   #   Helvetica => {
   #      Bold   => $pdf->corefont( 'Helvetica-Bold',    -encoding => 'latin1' ),
   #      Roman  => $pdf->corefont( 'Helvetica',         -encoding => 'latin1' ),
   #      Italic => $pdf->corefont( 'Helvetica-Oblique', -encoding => 'latin1' ),
   #   },
   #   Gotham => {
   #      Bold  => $pdf->ttfont('Gotham-Bold.ttf', -encode => 'latin1'),
   #      Roman => $pdf->ttfont('Gotham-Light.otf', -encode => 'latin1'),
   #   },
   #);
}


=head1 AUTHOR

Jay Hannah, C<< <jay at jays.net> >>

=head1 BUGS / SUPPORT

See PDF::TextBlock.

=head1 COPYRIGHT & LICENSE

Copyright 2009-2013 Jay Hannah, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of PDF::TextBlock::Font
