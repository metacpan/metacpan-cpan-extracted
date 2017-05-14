###  $Id:  $
####------------------------------------------
## @file
# Define GUIWindow Class
# GUI Widgets and related capabilities
#

## @class GUIWindow
# Provide a GUI with OpenGL.  Window is the top level Frame associated
# with a GL (sub)window

package OpenGL::QEng::GUIWindow;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::GUIFrame/;

#--------------------------------------------------
## @cmethod % new()
# Create a GUIWindow
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $GLwindow = delete $props->{GLwindow};
  die 'oops -- no parent window' unless defined $GLwindow;
  my $x = delete($props->{x}) || 0;
  my $y = delete($props->{y}) || 0;

  $props->{x}        = 0;
  $props->{y}        = 0;
  $props->{width}  ||= 256;
  $props->{height} ||= 256;
  my $self = OpenGL::QEng::GUIFrame->new($props);
  $self->{parent} = glutCreateSubWindow($GLwindow,
					$x,$y,
					$self->{width},$self->{height});
  bless($self,$class);

  $self->create_accessors;
  $self;
}

#------------------------------------------
## @method draw()
#  Draw the background for the GUI area
sub draw {
  my ($self) = @_;
  die 'wrong Frame' if ref $self->parent;

  # Disable depth test and lighting for 2D elements
  glDisable(GL_DEPTH_TEST);
  glDisable(GL_LIGHTING);

  # Set the orthographic viewing transformation
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(0,$self->{width},$self->{height},0,-1,1);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  $self->SUPER::draw;

  glutSwapBuffers();
}

#==================================================================
###
### Test Driver for GUIMaster Object
###
if (not defined caller()) {
  package main;

  require OpenGL;
  require GUIButton;

  OpenGL::glutInit;
  OpenGL::glutInitDisplayMode(OpenGL::GLUT_RGB   |
			      OpenGL::GLUT_DEPTH |
			      OpenGL::GLUT_DOUBLE);
  OpenGL::glutInitWindowSize(800,400);
  OpenGL::glutInitWindowPosition(200,100);
  my $win1 = OpenGL::glutCreateWindow("OpenGL GUIButton Test");
  glViewport(0,0,400,400);
  my $pwin = glutCreateSubWindow($win1, 0,0, 400,400);
  setup3D();

  ## build the 2D panel
   my $GUIRoot = GUIWindow->new(GLwindow=> $win1,
			      x       => 400,
			      y       => 0,
			      width   => 400,
			      height  => 400,
			     );

  $GUIRoot->adopt(GUIButton->new(x=>10,y=>10,
				 width=>52,height=>32,text=>'Exit',
				 clickCallback=>sub{exit(0)},
				));

  glutDisplayFunc(      sub{ $GUIRoot->draw(@_) });
  glutMouseFunc(        sub{ $GUIRoot->mouseButton(@_) });
  glutMotionFunc(       sub{ $GUIRoot->mouseMotion(@_) });
  glutPassiveMotionFunc(sub{ $GUIRoot->mousePassiveMotion(@_) });

  glutMainLoop;




  sub setup3D {

    my $rtri =0;              ## triangle rotation

    my $step = sub {
      glutSetWindow($pwin);
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
      glLoadIdentity();		     # Reset The View
      glTranslatef(0.0, 0.0, -6.0);  # Move into the screen 6.0 units.
      glRotatef($rtri, 0.0, 1.0, 0.0);
      glBegin(GL_POLYGON);
      glColor3f(1.0, 0.0, 0.0);	     # Red
      glVertex3f(0.0, 1.0, 0.0);     # Top
      glColor3f(0.0, 1.0, 0.0);	     # Green
      glVertex3f(1.0, -1.0, 0.0);    # Bottom Right
      glColor3f(0.0, 0.0, 1.0);	     # Blue
      glVertex3f(-1.0, -1.0, 0.0);   # Bottom Left
      glEnd();			     # We are done with the triangle
      $rtri+=1;

      glutSwapBuffers();
    };

    glClearColor(0.0, 0.0, 0.0, 0.0); # Set up 3D calls
    glClearDepth(1.0);
    glDepthFunc(GL_LESS);
    glEnable(GL_DEPTH_TEST);
    glShadeModel(GL_SMOOTH);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(45.0, 1.0, 0.1, 100.0);

    glMatrixMode(GL_MODELVIEW);
    glutDisplayFunc($step);
    glutIdleFunc($step);
  }
}
#------------------------------------------------------------------------------
1;

__END__

#==================================================================
###
### Test Driver for GUIMaster Object
###
if (not defined caller()) {
  package main;

  require OpenGL;
  require GUIButton;

  my $winsize = 400;
  my $winw = $winsize;
  my $winh = $winsize;

  OpenGL::glutInit;
  OpenGL::glutInitDisplayMode(OpenGL::GLUT_RGB   |
			      OpenGL::GLUT_DEPTH |
			      OpenGL::GLUT_DOUBLE);
  OpenGL::glutInitWindowSize($winsize,$winsize);
  OpenGL::glutInitWindowPosition(200,100);
  my $win1 = OpenGL::glutCreateWindow("OpenGL GUIMaster Test");
  glViewport(0,0,$winw,$winh);

  my $GUIRoot = OpenGL::QEng::GUIMaster->new(x=>0,y=>0,
			       width=>$winsize,height=>$winsize);

  $GUIRoot->adopt(OpenGL::QEng::GUIButton->new(x=>10,y=>10,
				 width=>32,height=>32,text=>'Button'));

  glutDisplayFunc(      sub{ $GUIRoot->GUIDraw(@_) });
  glutMouseFunc(        sub{ $GUIRoot->mouseButton(@_) });
  glutMotionFunc(       sub{ $GUIRoot->mouseMotion(@_) });
  glutPassiveMotionFunc(sub{ $GUIRoot->mousePassiveMotion(@_) });

  glutMainLoop;
}


=head1 NAME

GUI??? - Library for implementing GUIs with OpenGL

=head1 SYNOPSIS

  # Simple Example

  #!/usr/bin/perl -w
  use strict;
  use GUIFrame;
  use GUIButton;

  our $rtri =0;              ## triangle rotation

  OpenGL::glutInit;
  OpenGL::glutInitDisplayMode(OpenGL::GLUT_RGB   |
			      OpenGL::GLUT_DEPTH |
			      OpenGL::GLUT_DOUBLE);
  OpenGL::glutInitWindowSize(800,400);
  OpenGL::glutInitWindowPosition(200,100);
  my $win1 = OpenGL::glutCreateWindow("OpenGL GUIButton Test");
  glViewport(0,0,400,400);
  my $pwin = glutCreateSubWindow($win1,
				    0,0, 400,400);
  &setup3D;

  ## build the 2D panel
   my $GUIRoot = GUIWindow->new(GLwindow=> $win1,
			      x       => 400,
			      y       => 0,
			      width   => 400,
			      height  => 400,
			     );

  $GUIRoot->adopt(GUIButton->new(x=>10,y=>10,
				 width=>52,height=>32,text=>'Exit',
				 clickCallback=>sub{exit(0)},
				));

  glutDisplayFunc(      sub{ $GUIRoot->GUIDraw(@_) });
  glutMouseFunc(        sub{ $GUIRoot->mouseButton(@_) });
  glutMotionFunc(       sub{ $GUIRoot->mouseMotion(@_) });
  glutPassiveMotionFunc(sub{ $GUIRoot->mousePassiveMotion(@_) });

  glutMainLoop;


  sub step {
    glutSetWindow($pwin);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();		     # Reset The View
    glTranslatef(0.0, 0.0, -6.0);    # Move into the screen 6.0 units.
    glRotatef($rtri, 0.0, 1.0, 0.0);
    glBegin(GL_POLYGON);
    glColor3f(1.0, 0.0, 0.0);	     # Red
    glVertex3f(0.0, 1.0, 0.0);	     # Top
    glColor3f(0.0, 1.0, 0.0);	     # Green
    glVertex3f(1.0, -1.0, 0.0);	     # Bottom Right
    glColor3f(0.0, 0.0, 1.0);	     # Blue
    glVertex3f(-1.0, -1.0, 0.0);     # Bottom Left
    glEnd();			     # We are done with the triangle
    $rtri+=1;

    glutSwapBuffers();
  }

sub setup3D {
  glClearColor(0.0, 0.0, 0.0, 0.0); # Set up 3D calls
  glClearDepth(1.0);
  glDepthFunc(GL_LESS);
  glEnable(GL_DEPTH_TEST);
  glShadeModel(GL_SMOOTH);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluPerspective(45.0, 1.0, 0.1, 100.0);

  glMatrixMode(GL_MODELVIEW);
  glutDisplayFunc(\&step);
  glutIdleFunc(\&step);
}

=head1 DESCRIPTION

GUI???? is a tool for creating user interfaces with OpenGL widgets.
It allows 2D controls to be associated with 3D images without
requiring sharing execution with a tool like Tk.  It provides widgets
for labels, buttons, text display and canvas drawing areas. The canvas
supports drawing lines, circles, polygons and images.

=head2 Basic Overview

To implement an application with a 3D window and a 2D window, the base
window is created with glutCreateWindow and divided creating two
subwindows with glutCreateSubWindow.  The 2D subwindow is passed as
wid (window ID) to the constructor of a GUIFrame.  The desired GUI widgets
are created using the adopt method of GUIFrame. Similarly, objects to
be drawn on a GUI canvas are created with the create method of the
GUICanvas.

All of the objects have accessor routines for each option allowing them
to be changed dynamically.

=head1 OBJECT DESCRIPTIONS

The GUI??? is composed of the GUIWindow, GUIFrame, GUIButton, GUICanvas, and
GUIText objects.

=head2 OBJECT NAME

B<GUIWindow> - Create a window to hold 2D widgets. GUIWindow is a
subclass of GUIFrame.

=head2 SYNOPSIS

$guiWindow = B<GUIWindow>->new(?options?);

=head2 OPTIONS

Name: GLwindow
 Specifies the OpenGL window that the subwindow will be placed in

Also, accepts all the options of a GUIFrame.

=head2 METHODS

C<< $guiWindow->B<adopt>(widget); >>
  Add a widget to the window.

C<< $guiWindow->B<draw>; >>
  Draw the window and all its children

=head2 SPECIAL METHODS

These methods are not normally called directly. They are passed to glut.

C<< $guiWindow->B<draw>(@_); >>
  Passed to glutDisplayFunc.

C<< $guiWindow->B<mouseButton>(@_); >>
  Passed to glutMouseFunc.

C<< $guiWindow->B<mouseMotion>(@_); >>
  May be passed to glutMotionFunc.

C<< $guiWindow->B<mousePassiveMotion>(@_); >>
  May be passed to glutPassiveMotionFunc.

=head2 OBJECT NAME

B<GUIFrame> - Create frame to hold 2D widgets

=head2 SYNOPSIS

$guiFrame = B<GUIFrame>->new(?options?);

=head2 OPTIONS

Name: color
 Specifies the background color for the frame as a text string.

Names: x and y
 Coordinates of the upper left corner of the frame.

Names: height and width
 Size of the frame

Name: texture
 Optional OpenGL texture name to display the frame as a texture rather
 than in a single color.

=head2 METHODS

C<< $guiFrame->B<adopt>(widget); >>
  Add a widget to the frame.

C<< $guiFrame->B<draw>; >>
  Draw the frame and all its children

=head2 OBJECT NAME

B<GUIButton> - Create push button widget

=head2 SYNOPSIS

$button = B<GUIButton>->new(?options?);

=head2 OPTIONS

Name: color
   Specifies the background color for the button as a text string.

Name: font
   One of the available glut bitmapped fonts.  As a value, not a string.

Names: x and y
   Coordinates of the upper left corner of the button.

Names: height and width
   Size of the button

Name: text
   Optional text.

Name: relief
   Set the appearance of the button. Choices are 'flat' and 'raised'.
   'raised' is the default.

Name: textColor
   Text color name for the text.  Defaults to black.

Name: texture
   Optional OpenGL texture name to display on the button.

Name: clickCallback
   Code reference for the routine to call when the button is clicked
   (pressed and released).

Name: pressCallback
   Code reference for the routine to call when the button is pressed but
   not yet released.

=head2 METHODS

C<< $button->B<draw>; >>
       Draw the button.

=head2 OBJECT NAME

B<GUIiButton> - Create push button widget with images for up and down

=head2 SYNOPSIS

$button = B<GUIiButton>->new(?options?);

=head2 OPTIONS

Name: font
   One of the available glut bitmapped fonts.  As a value, not a string.

Names: x and y
   Coordinates of the upper left corner of the button.

Names: height and width
   Size of the button.

Name: text
   Optional text.

Name: textColor
   Text color name for the text.  Defaults to black.

Name: texture
   Reference to an array of OpenGL texture names to display on the button
   to represent the button state.

Name: clickCallback
   Code reference for the routine to call when the button is clicked
   (pressed and released).

Name: pressCallback
   Code reference for the routine to call when the button is pressed but
   not yet released.


=head2 METHODS

C<< $button->B<draw>; >>
       Draw the button.

=head2 OBJECT NAME

B<GUICanvas> - Create canvas widget that allows drawing and selection with
               the mouse

=head2 SYNOPSIS

$canvas = B<GUICanvas>->new(?options?);

=head2 OPTIONS

Name: color
   Specifies the background color for the canvas as a text string.

Names: x and y
   Coordinates of the upper left corner of the canvas.

Names: height and width
   Size of the canvas

Name: relief
   Set the appearance of the canvas. Choices are 'flat' and 'sunken'.
   'sunken' is the default.

Name: clickCallback
   Code reference for the routine to call when the canvas is clicked
   (pressed and released).  The routine called must perform these calculations
   to determine the relative x,y on the canvas.
     C<< my ($x,$y) = ($self->{mouse}{x},$self->{mouse}{y});
        $x -= $self->{x};
        $y -= $self->{y}; >>

=head2 METHODS

C<< $canvas->B<draw>; >>
       Draw the canvas.

C<< $canvas->B<create>('type',?options?); >>
       Create a object on the canvas.  C<type> can be 'Circle', 'Line',
       'Image', or 'Poly'.  The most of the options will depend on type.
       All types require x and y.

=over 4

=head2 CANVAS OBJECTS

=head3 Circle - Circle (really a disk) on the canvas

=head3 Options

Name: color
   Specifies the color for the circle as a text string.

Name: radius
   Radius of the circle

=head3 Image - Image on the canvas

=head3 Options

Name: texture
   Specifies the texture to display.

Names: height and width
   Size of the image

=head3 Line - Line on the canvas

=head3 Options

Name: color
   Specifies the color for the line as a text string.

Name: width
   Width of the line in pixels.

Names: x2 and y2
   Coordinates of the 2nd end of the line.

=head3 Poly - Filled polygon on the canvas

=head3 Options

Name: color
   Specifies the color for the polygon as a text string.

Name:
   As many pairs of coordinates as are required to describe the polygon.
   They are not preceeded by an option name.

=back

=head2 OBJECT NAME

B<GUILabel> - Create label widget

=head2 SYNOPSIS

$label = B<GUILabel>->new(?options?);

=head2 OPTIONS

Name: font
   One of the available glut bitmapped fonts.  As a value, not a string.

Names: x and y
   Coordinates of the upper left corner of the label.

Names: height and width
   Size of the area to center the text in.  Defaults to 0x0 and label
   will not display.

Name: text
   Label text.

Name: textColor
   Text color name for the text.  Defaults to black.

=head2 METHODS

C<< $label->B<draw>; >>
       Draw the label.


=head2 OBJECT NAME

B<GUIText> - Create text display area

=head2 SYNOPSIS

$text = B<GUIText>->new(?options?);

=head2 OPTIONS

Name: color
   Specifies the background color for the text display area as a text string.

Name: font
   One of the available glut bitmapped fonts.  As a value, not a string.

Names: x and y
   Coordinates of the upper left corner of the text display area.

Name: relief
   Set the appearance of the canvas. Choices are 'flat' and 'sunken'.
   'sunken' is the default.

Name: text
   Initial text.

Name: textColor
   Color name for the text.  Defaults to 'black'.

=head2 METHODS

C<< $text->B<draw>; >>
       Draw the text.

C<< $text->B<insert>('more text') >>
       Adds the text and scrolls up the old text

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

The idea for GUI??? was inspired by a C capability by Rob Bateman.

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

