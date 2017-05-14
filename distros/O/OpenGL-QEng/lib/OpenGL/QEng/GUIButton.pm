###  $Id: GUIButton.pm 322 2008-07-19 22:32:21Z duncan $
####------------------------------------------
## @file
# Define GUIButton Class
# GUI Widgets and related capabilities
#

## @class GUIButton
# Provide a GUI Button in OpenGL

package OpenGL::QEng::GUIButton;

use strict;
use warnings;
use OpenGL qw/:all/;
use OpenGL::QEng::TextureList;

use base qw/OpenGL::QEng::GUIThing/;

#--------------------------------------------------
## @cmethod % new()
# Create a GUIButton
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);
  my $self = OpenGL::QEng::GUIThing->new();
  $self->{clickCallback}    = undef;
  $self->{pressCallback}    = undef;
  $self->{text}             = undef;
  $self->{texture}          = undef;
  $self->{color}            = 'gray60';
  $self->{textColor}        = 'white';
  $self->{highlighted}      = 0;
  $self->{relief}           = 'raised';
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  $self;
}

######
###### Public Instance Methods
######

## @method draw()
#  Draw the background for the GUI area
sub draw {
  my ($self) = @_;

  if ($self->{texture}) {
    $self->pickTexture($self->{texture});
    glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_T, GL_REPEAT);
    glEnable(GL_TEXTURE_2D);
  } else {
    $self->setColor($self->{color}) if defined $self->{color};
  }
  # draw texture for the button.
  ### TODO ????? Texture needs to shift right and down like text when depressed
  glBegin(GL_QUADS);
  glTexCoord2f(0,1); glVertex2i($self->x,             $self->y              );
  glTexCoord2f(0,0); glVertex2i($self->x,             $self->y+$self->height);
  glTexCoord2f(1,0); glVertex2i($self->x+$self->width,$self->y+$self->height);
  glTexCoord2f(1,1); glVertex2i($self->x+$self->width,$self->y              );
  glEnd();
  glDisable(GL_TEXTURE_2D);

  if ($self->{relief} eq 'raised'){
    glLineWidth(3); # Draw an outline around the button with width 3

    # The colours for the outline are reversed when the button is down.
    if ($self->{state}) { glColor3f(0.4,0.4,0.4); }
    else                { glColor3f(0.8,0.8,0.8); }

    glBegin(GL_LINE_STRIP);
    glVertex2i($self->{x}+$self->{width}, $self->{y}                );
    glVertex2i($self->{x},                $self->{y}                );
    glVertex2i($self->{x},                $self->{y}+$self->{height});
    glEnd();

    if ($self->{state}) { glColor3f(0.8,0.8,0.8); }
    else                { glColor3f(0.4,0.4,0.4); }

    glBegin(GL_LINE_STRIP);
    glVertex2i( $self->{x}    , $self->{y}+$self->{height} );
    glVertex2i( $self->{x}+$self->{width}, $self->{y}+$self->{height} );
    glVertex2i( $self->{x}+$self->{width}, $self->{y}      );
    glEnd();

    glLineWidth(1);
  }
  if ($self->{text}) {
    # Calculate the x and y coords for the text string in order to center it.
    my $fontx =
      $self->{x} + ($self->{width}
		    - $self->glutBitmapLength($self->{font},
					      $self->{text})) / 2 ;
    # adjustment of 23 is chosen by eye because it seems to work
    my $fonty = $self->{y} + ($self->{height}+23)/2;

    # if the button is pressed, make it look as though the string has
    # been pushed down. It's just a visual thing to help with the
    # overall look....
    if ($self->{state}) {
      $fontx+=2;
      $fonty+=2;
    }

    # If the cursor is currently over the button we offset the text string
    # and draw a shadow
    if ($self->{highlighted}) {
      glColor3f(0,0,0);
      $self->write($self->{font},$self->{text},$fontx,$fonty);
      $fontx--;
      $fonty--;
    }

    glColor3f(1,1,1);
    $self->setColor($self->{textColor}) if defined $self->{textColor};
    my @lines = split ' ',$self->{text};
    my $lines = @lines;
    $fonty = $fonty -15*$lines/2;
    for my $line ( @lines) {
      my $fontx =
	$self->{x} + ($self->{width}
		    - $self->glutBitmapLength($self->{font},
					      $line)) / 2 ;
      $self->write($self->{font},$line,$fontx,$fonty);
      $fonty+= 15;
    }
    #$self->write($self->{font},$self->{text},$fontx,$fonty);
  }
}

#==================================================================
###
### Test Driver for GUIButton Object
###
if (not defined caller()) {
  package main;

  require OpenGL;
  require GUIMaster;

  my $winsize = 400;
  my $winw = $winsize;
  my $winh = $winsize;
  OpenGL::glutInit;
  OpenGL::glutInitDisplayMode(OpenGL::GLUT_RGB   |
			      OpenGL::GLUT_DEPTH |
			      OpenGL::GLUT_DOUBLE);
  OpenGL::glutInitWindowSize($winsize,$winsize);
  OpenGL::glutInitWindowPosition(200,100);
  my $win1 = OpenGL::glutCreateWindow("OpenGL GUIButton Test");
  glViewport(0,0,$winw,$winh);

  my $GUIRoot = OpenGL::QEng::GUIMaster->new(wid   => $win1,
			       x     => 0,
			       y     => 0,
			       width => $winsize,
			       height=> $winsize);

  $GUIRoot->adopt(OpenGL::QEng::GUIButton->new(x     => 10,
				 y     => 10,
				 width => 32,
				 height=> 32,
				 text  => ' '));

  glutDisplayFunc(      sub{ $GUIRoot->GUIDraw(@_) });
  glutMouseFunc(        sub{ $GUIRoot->mouseButton(@_) });
  glutMotionFunc(       sub{ $GUIRoot->mouseMotion(@_) });
  glutPassiveMotionFunc(sub{ $GUIRoot->mousePassiveMotion(@_) });

  glutMainLoop;
}

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

GUIButton -- 2D/3D button with text

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

