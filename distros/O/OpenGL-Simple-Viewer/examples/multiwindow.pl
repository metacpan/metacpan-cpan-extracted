#!/usr/bin/env perl
use strict;
use warnings;
use OpenGL::Simple qw(:all);
use OpenGL::Simple::GLUT qw(:all);
use OpenGL::Simple::Viewer;

glutInit;

my $v = new OpenGL::Simple::Viewer; # Should Just Work.
$v->{'draw_geometry'} = sub { glutSolidIcosahedron; };

my $v2 = new OpenGL::Simple::Viewer(
       title => 'Shiny window',        # Set window title
       nearclip => 0.1,                # Near clipping plane
       translatescale => 0.01,         # Mouse translation speed
       zoomscale => 0.02,              # Mouse zoom speed
       screenx => 256,                 # Initial window dimensions
       screeny => 256,
       sphererad => 256*0.5,           # Virtual trackball size
       displaymode => GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH,
                                       # Window display mode

       initialize_gl => sub {
               glClearColor(0,0,1,1);  # Blue background
       },

       draw_background => sub {
               # Clear the window before drawing geometry
               glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
       },

       # Draw a teapot.
       draw_geometry => sub { glutSolidTeapot(1.0); },

);

glutMainLoop;
