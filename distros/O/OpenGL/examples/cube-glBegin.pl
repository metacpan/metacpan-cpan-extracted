#       cube-glBegin - using OpenGL with glBegin
#
#  Draws a 3-D cube, viewed with perspective, stretched
#  along the y-axis.
#  Adapted from "cube.c", chapter 3, listing 3-1,
#  page 70, OpenGL Programming Guide

use strict;
use warnings;
use OpenGL;

sub wirecube {
  # adapted from libaux
  my ($s) = @_;
  $s /= 2.0;
  my @x=(-$s,-$s,-$s,-$s,$s,$s,$s,$s);
  my @y=(-$s,-$s,$s,$s,-$s,-$s,$s,$s);
  my @z=(-$s,$s,$s,-$s,-$s,$s,$s,-$s);
  my @f=(
    #0, 1, 2, 3, 0,
    3, 2, 6, #7, 3,
    7, 4, 0, 3, #7,
    7, 6, 5, #4, 7,
    4, 0, 1, #5, 4,
    5, 1, 2, #6, 5,
  );
  glBegin(GL_LINE_STRIP);
  for (@f) {
    glVertex3d($x[$_],$y[$_],$z[$_]);
  }
  glEnd();
}
sub display {
  glClear(GL_COLOR_BUFFER_BIT);
  glColor3f(1.0, 1.0, 1.0);
  glLoadIdentity();	#  clear the matrix
  glTranslatef(0.0, 0.0, -5.0);	#  viewing transformation
  glScalef(1.0, 2.0, 1.0);	#  modeling transformation
  wirecube(1.0);
  glpFlush();
}

sub myReshape {
  # glViewport(0, 0, w, h);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glFrustum(-1.0, 1.0, -1.0, 1.0, 1.5, 20.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity ();
}

glpOpenWindow;
glShadeModel(GL_FLAT);
myReshape();
display();

glpMainLoop;
