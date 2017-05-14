###  $Id: GUICanvasImage.pm 322 2008-07-19 22:32:21Z duncan $
####------------------------------------------
## @file
# Define GUICanvasLine Class
# GUI Widgets and related capabilities
#

## @class GUICanvasLine
# Draw a line on a GUICanvas

package OpenGL::QEng::GUICanvasLine;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::GUICanvasThing/;

#--------------------------------------------------
## @cmethod % new()
# Create a GUICanvasLine
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);
  my $self = OpenGL::QEng::GUICanvasThing->new();
  $self->{width}  = 1;
  $self->{x2}     = 0;
  $self->{y2}     = 0;
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  $self;
}

#--------------------------------------------------
## @method draw()
#  Draw the line on the canvas
sub draw {
  my ($self, $xbase, $ybase, $widthmax, $heightmax) = @_;

  $self->tErr('canvasLine3');
  # Convert to canvas relative coords and check that we fit
  my $x1 = ($xbase + $self->{x});
  my $y1 = ($ybase + $self->{y});
  my $x2 = ($xbase + $self->{x2});
  my $y2 = ($ybase + $self->{y2});
  $self->setColor($self->{color});

  glLineWidth($self->{width});
  #if ($x1<0 or $y1<0 or $x2>$widthmax or $y2>$heightmax) {
    #print STDERR "Line won't fit $x1,$y1 -- $x2,$y2 (mw=$widthmax, mh=$heightmax)\n";
    #$self->setColor('red');
  #}

  glBegin(GL_LINE_STRIP);
#  glVertex2i( $x1, $y1);
#  glVertex2i( $x2, $y2);
  glVertex2f ($x1, $y1);
  glVertex2f ($x2, $y2);
  glEnd();
  $self->tErr('canvasLine');
}

#==================================================================

1;

__END__

=head1 NAME

GUICanvasLine -- Draw a line on a GUICanvas

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

