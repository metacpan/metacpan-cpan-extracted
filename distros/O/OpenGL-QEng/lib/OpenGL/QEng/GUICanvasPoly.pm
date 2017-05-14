###  $Id: GUICanvasPolygon.pm 322 2008-07-19 22:32:21Z duncan $
####------------------------------------------
## @file
# Define GUICanvasPoly Class
# GUI Widgets and related capabilities
#

## @class GUICanvasPoly
# Draw a polygon on a GUICanvas

package OpenGL::QEng::GUICanvasPoly;

use strict;
use warnings;
use OpenGL qw/:all/;
use OpenGL::QEng::TextureList;

use base qw/OpenGL::QEng::GUICanvasThing/;

#--------------------------------------------------
## @cmethod % new()
# Create a GUICanvasPolygon
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);
  my $self = OpenGL::QEng::GUICanvasThing->new();
  $self->{xs}     = [];
  $self->{ys}     = [];
  bless($self,$class);

  # extract coordinate pairs from arg list
  my $done = 0;
  while (@props and not $done) {
    my $x = shift @props;
    my $y = shift @props;

    no warnings 'numeric';
    if ( $x eq $x+0 and $y eq $y+0) {
      push @{$self->{xs}}, $x;
      push @{$self->{ys}}, $y;
    } else {
      push @props,($x,$y);
      $done = 1;
    }

  }
  $self->passedArgs({@props});
  $self->create_accessors;
  $self;
}

######
###### Public Instance Methods
######

## @method draw()
#  Draw the polygon on the canvas
sub draw {
  my ($self, $xbase, $ybase, $widthmax, $heightmax) = @_;

  $self->setColor($self->{color});
  # Convert to canvas relative coords and check that we fit
  my $len = @{$self->{xs}};

  $self->tErr('canvasPolygon');
  glBegin(GL_POLYGON);
  for (my $i=0; $i<$len; $i++) {
    my $x = $xbase + ${$self->{xs}}[$i];
    my $y = $ybase + ${$self->{ys}}[$i];

    if (0 && ($x<0 or $y<0 or $x>$widthmax or $y>$heightmax)) {
      print STDERR "Polygon won't fit\n";
      glEnd();
      return;
    }
    glVertex2i($x, $y);
  }
  glEnd();
  $self->tErr('canvasPolygon');
}

#==================================================================

1;

__END__

=head1 NAME

GUICanvasPoly -- draw a polygon (polyline?) on a GUICanvas

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

