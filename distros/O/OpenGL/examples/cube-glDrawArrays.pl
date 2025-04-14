#       cube-glDrawArrays - using OpenGL with glDrawArrays
#
#  Draws a 3-D cube, viewed with perspective, stretched
#  along the y-axis.
#  Adapted from "cube.c", chapter 3, listing 3-1,
#  page 70, OpenGL Programming Guide

use strict;
use warnings;
use OpenGL qw(:all glpMainLoop glpOpenWindow glpFlush);

my $verts;
sub wirecube_setup {
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
  my @coords;
  for (@f) {
    push @coords, $x[$_],$y[$_],$z[$_];
  }
  $verts = OpenGL::Array->new_list(GL_FLOAT, @coords);
  glVertexPointer_p(3, $verts);
  glEnableClientState(GL_VERTEX_ARRAY);
}

sub wirecube {
  glDrawArrays(GL_LINE_STRIP, 0, 16);
}
sub display{
  glClear(GL_COLOR_BUFFER_BIT);
  glColor3f(1.0, 1.0, 1.0);
  glLoadIdentity();	#  clear the matrix
  glTranslatef(0.0, 0.0, -5.0);	#  viewing transformation
  glScalef(1.0, 2.0, 1.0);	#  modeling transformation
  wirecube();
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
wirecube_setup(1.0);
glShadeModel(GL_FLAT);
myReshape();
display();

glpMainLoop;
