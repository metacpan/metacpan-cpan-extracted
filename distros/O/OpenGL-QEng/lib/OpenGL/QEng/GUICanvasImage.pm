###  $Id: GUICanvasImage.pm 322 2008-07-19 22:32:21Z duncan $
####------------------------------------------
## @file
# Define GUICanvasImage Class
# GUI Widgets and related capabilities
#

## @class GUICanvasImage
# Render an image on a GUICanvas

package OpenGL::QEng::GUICanvasImage;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::GUICanvasThing/;

#--------------------------------------------------
## @cmethod % new()
# Create a GUICanvasImage
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);
  my $self = OpenGL::QEng::GUICanvasThing->new();
  $self->{texture} = undef;
  $self->{width}   = 0;
  $self->{height}  = 0;
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  $self;
}

######
###### Public Instance Methods
######

## @method draw()
#  Draw the image on the canvas
sub draw {
  my ($self, $xbase, $ybase, $widthmax, $heightmax) = @_;

  # my coords are image center. Add canvas origin and generate corners
  my $x1 = $self->{x} - $self->{width}/2;
  my $y1 = $self->{y} - $self->{height}/2;
  my $x2 = $x1 + $self->{width};
  my $y2 = $y1 + $self->{height};

  if (0 && ($x1 <0 or $y1<0 or $x2 >$widthmax or $y2 > $heightmax)) {
    print STDERR "Image won't fit\n";
    return;
  }

  if ($self->{texture}) {
    $self->pickTexture($self->{texture});
    glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_T, GL_REPEAT);
    glEnable(GL_TEXTURE_2D);
  } else {
    $self->setColor($self->{color}) if defined $self->{color};
  }
  # draw image as a texture on a rectangle
  glBegin(GL_QUADS);
  glTexCoord2f(0.0,1.0);
  glVertex2i($x1+$xbase, $y1+$ybase);
  glTexCoord2f(0.0,0.0);
  glVertex2i($x1+$xbase, $y2+$ybase);
  glTexCoord2f(1.0,0.0);
  glVertex2i($x2+$xbase, $y2+$ybase);
  glTexCoord2f(1.0,1.0);
  glVertex2i($x2+$xbase, $y1+$ybase);
  glEnd();
  glDisable(GL_TEXTURE_2D);

}

#==================================================================

1;

__END__

=head1 NAME

GUICanvasImage -- Render an image on a GUICanvas

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

