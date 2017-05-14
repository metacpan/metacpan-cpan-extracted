###  $Id:  $
####------------------------------------------
## @file
# Define GUIFrame Class
# GUI Widgets and related capabilities
#

## @class GUIFrame
# Provide a GUI with OpenGL.  Frame is the parent for the GUI objects.

package OpenGL::QEng::GUIFrame;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::GUIThing/;

### This work is based on C code written by Rob Bateman <<XXX need reference>>

#--------------------------------------------------
## @cmethod % new()
# Create a GUIFrame
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);

  my $self = OpenGL::QEng::GUIThing->new();
  $self->{color} = undef;
  $self->{mouse} = {x      => 0, #  x   -- the x coordinate of the mouse cursor
		    y      => 0, #  y   -- the y coordinate of the mouse cursor
		    lmb    => 0, #  lmb -- is the left button pressed?
		    mmb    => 0, #  mmb --	is the middle button pressed?
		    rmb    => 0, #  rmb -- is the right button pressed?
		    xpress => 0, #  xpress -- the x of the button *press*
		    ypress => 0, #  ypress -- the y of the button *press*
		   };
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  $self;
}

#------------------------------------------
sub adopt {
  my ($self,$child) = @_;

  push (@{$self->{children}},$child);
}

#------------------------------------------
sub draw {
  my ($self) = @_;

  if ($self->{texture}) {
    $self->pickTexture($self->{texture});
    glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_T, GL_REPEAT);
    glEnable(GL_TEXTURE_2D);
    glBegin(GL_QUADS);
    glTexCoord2f(0,0);glVertex2i($self->x,             $self->y);
    glTexCoord2f(0,1);glVertex2i($self->x,             $self->y+$self->height);
    glTexCoord2f(1,1);glVertex2i($self->x+$self->width,$self->y+$self->height);
    glTexCoord2f(1,0);glVertex2i($self->x+$self->width,$self->y);
    glEnd();
    glDisable(GL_TEXTURE_2D);
  }
  elsif (defined $self->{color}) {
    $self->setColor($self->{color}) if defined $self->{color};
    glBegin(GL_QUADS);
    glVertex2i($self->x,             $self->y);
    glVertex2i($self->x,             $self->y+$self->height);
    glVertex2i($self->x+$self->width,$self->y+$self->height);
    glVertex2i($self->x+$self->width,$self->y);
    glEnd();
  }
  for my $child (@{$self->{children}}) {
    $child->draw;
  }
}

#------------------------------------------------------------------------------
## \brief   This function is called whenever a mouse button is pressed
#           or released
#  \param   mbuttons - GLUT_LEFT_BUTTON, GLUT_RIGHT_BUTTON,
#                      or GLUT_MIDDLE_BUTTON
#  \param   state  - GLUT_UP or GLUT_DOWN depending on whether the mouse
#                    was released or pressed respectivly.
#  \param   x	   - the x-coord of the mouse cursor.
#  \param   y	   - the y-coord of the mouse cursor.
#
sub mouseButton {
  my ($self, $mbuttons, $state, $x, $y) = @_;

  $self->{mouse}{x} = $x;
  $self->{mouse}{y} = $y;

  if ($state == GLUT_DOWN) {	# Which button was pressed?
    $self->{mouse}{xpress} = $x; #save the press loc
    $self->{mouse}{ypress} = $y;

    if    ($mbuttons == GLUT_LEFT_BUTTON) {
      $self->{mouse}{lmb} = 1;
      $self->buttonPress($x,$y);
    }
    elsif ($mbuttons == GLUT_MIDDLE_BUTTON) {
      $self->{mouse}{mmb} = 1;
    }
    elsif ($mbuttons == GLUT_RIGHT_BUTTON) {
      $self->{mouse}{rmb} = 1;
    }
  } else {			# Which button was released?
    if ($mbuttons == GLUT_LEFT_BUTTON) {
      $self->{mouse}{lmb} = 0;
      $self->buttonRelease($x,$y);
    }
    elsif ($mbuttons ==  GLUT_MIDDLE_BUTTON) {
      $self->{mouse}{mmb} = 0;
    }
    elsif ($mbuttons ==  GLUT_RIGHT_BUTTON) {
      $self->{mouse}{rmb} = 0;
    }
  }
  glutPostRedisplay(); # force redraw of gui
}

#-----------------------------------------------------------------------------
sub buttonPress {
  my ($self, $x, $y) = @_;

  for my $child (@{$self->{children}}) {
    if ($child->inside($x,$y)) {
      $child->buttonPress($x,$y);
      return;
    }
  }
}

#---------------------------------------------------------------------------
sub buttonRelease {
  my ($self, $x, $y) = @_;

  for my $child (@{$self->{children}}) {
    if ($child->inside($self->{mouse}{xpress}, $self->{mouse}{ypress}) &&
	$child->inside($x,$y)) {
      $child->{mouse} = $self->{mouse};
      $child->buttonRelease($x,$y);
      return;
    }
  }
}

#---------------------------------------------------------------------------
sub buttonPassive {
  my ($self, $x, $y) = @_;

  for my $child (@{$self->{children}}) {
    if ($child->inside($x,$y)) {
      $child->buttonPassive($x,$y);
      return;
    }
  }
}


#----------------------------------------------------------------------------
# \brief  This function is called whenever the mouse cursor is moved
#         AND A BUTTON IS HELD.
# \param  x - the new x-coord of the mouse cursor.
# \param  y - the new y-coord of the mouse cursor.
#
sub mouseMotion {
  my ($self, $x, $y) = @_;

  $self->{mouse}{x} = $x;
  $self->{mouse}{y} = $y;
  $self->buttonPassive($x,$y);
  glutPostRedisplay();
}

#----------------------------------------------------------------------------
# \brief  This function is called whenever the mouse cursor is moved
#         AND NO BUTTONS ARE HELD.
# \param	x	-	the new x-coord of the mouse cursor.
# \param	y	-	the new y-coord of the mouse cursor.
#
sub mousePassiveMotion {
  my ($self, $x, $y) = @_;

  $self->{mouse}{x} = $x;
  $self->{mouse}{y} = $y;
  $self->buttonPassive($x,$y);
}

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

GUIFrame -- Frame is the parent for the GUI objects

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

