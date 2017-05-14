###  $Id: GUICanvasCircle.pm 322 2008-07-19 22:32:21Z duncan $
####------------------------------------------
## @file
# Define GUICanvasCircle Class
# GUI Widgets and related capabilities
#

## @class GUICanvasCircle
# Draw a circle on a GUICanvas

package OpenGL::QEng::GUICanvasCircle;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::GUICanvasThing/;

#--------------------------------------------------
## @cmethod % new()
# Create a GUICanvasCircle
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);
  my $self = OpenGL::QEng::GUICanvasThing->new();
  $self->{radius} = 0;
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  $self;
}

######
###### Public Instance Methods
######

## @method draw()
#  Draw the circle on the canvas
sub draw {
  my ($self, $xbase, $ybase, $widthmax, $heightmax) = @_;

  # my coords are circle center and radius.
  # Add canvas origin and generate extremes
  my $x1 = $self->{x} - $self->{radius};
  my $y1 = $self->{y} - $self->{radius};
  my $x2 = $self->{x} + $self->{radius};
  my $y2 = $self->{y} + $self->{radius};

  if (0 && ($x1 <0 or $y1<0 or $x2 >$widthmax or $y2 > $heightmax)) {
    print STDERR "Circle won't fit\n";
    return;
  }

  $self->setColor($self->{color});

  my $originX=$xbase+$self->{x};
  my $originY=$ybase+$self->{y};
  my $vectorY1=$originY;
  my $vectorX1=$originX;
  my $radius2 = $self->{radius};
  my $radius1 = 0;

  glBegin(GL_TRIANGLE_STRIP);
  for (my $i=0; $i<=360; $i+=10) {
    my $angle1=$i/57.29577957795135;
    my $angle2=($i+5)/57.29577957795135;
    my $vectorX1=$originX+($radius1*sin($angle1));
    my $vectorY1=$originY+($radius1*cos($angle1));
    my $vectorX2=$originX+($radius2*sin($angle2));
    my $vectorY2=$originY+($radius2*cos($angle2));
    glVertex2i($vectorX1,$vectorY1);
    glVertex2i($vectorX2,$vectorY2);
  }
  glEnd();

  $self->tErr('canvasCircle');
}

#==================================================================

1;

__END__

=head1 NAME

GUICanvasCircle -- Draw a circle on a GUICanvas

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

