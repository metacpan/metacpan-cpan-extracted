#       cube
#
#  Draws a 3-D cube, viewed with perspective, stretched
#  along the y-axis.
#  Adapted from "cube.c", chapter 3, listing 3-1,
#  page 70, OpenGL Programming Guide

use strict;
use warnings;
use OpenGL qw(
  glpOpenWindow glpMainLoop glpFlush glMatrixMode glLoadIdentity
  glFrustum glClear glColor3f glTranslatef glScalef glShadeModel
  GL_COLOR_BUFFER_BIT GL_PROJECTION GL_MODELVIEW GL_FLAT
  glGenBuffersARB_p glDeleteBuffersARB_p
  glBufferDataARB_p GL_STATIC_DRAW_ARB
  glEnableClientState glDisableClientState GL_VERTEX_ARRAY
  glBindBufferARB GL_ARRAY_BUFFER_ARB GL_ELEMENT_ARRAY_BUFFER_ARB
  glVertexPointer_p GL_FLOAT
  glDrawElements_c GL_LINE_STRIP GL_UNSIGNED_INT
);

# Vertex Buffer Object data
my ($TetraVertObjID,$TetraIndObjID);

my $root3 = sqrt(3);
my $sqrt23 = sqrt(2/3);    # height of side-length=1 = sqrt(2/3)
my $sqrt1_24 = sqrt(1/24); # geometric centre is minus 1/4 of that
my @tetra_verts = (
  0.5/$root3,-$sqrt1_24,       1,
  -1/$root3, -$sqrt1_24,       0,
  0.5/$root3,-$sqrt1_24,       -1,
  0,         -$sqrt1_24+$sqrt23,0,
);
my $tetra_verts = OpenGL::Array->new_list(GL_FLOAT,@tetra_verts);
my @tetra_inds = (
  0,1,2,0,3,1,2,3,
);
my $tetra_inds = OpenGL::Array->new_list(GL_UNSIGNED_INT,@tetra_inds);

sub wirecube_setup {
  ($TetraVertObjID,$TetraIndObjID) = glGenBuffersARB_p(2);
  $tetra_verts->bind($TetraVertObjID);
  glBufferDataARB_p(GL_ARRAY_BUFFER_ARB, $tetra_verts, GL_STATIC_DRAW_ARB);
  glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, $TetraIndObjID);
  glBufferDataARB_p(GL_ELEMENT_ARRAY_BUFFER_ARB, $tetra_inds, GL_STATIC_DRAW_ARB);
}

sub wirecube {
  # Render tetrahedron
  glEnableClientState(GL_VERTEX_ARRAY);
  glVertexPointer_p(3, $tetra_verts);
  glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, $TetraIndObjID);
  glDrawElements_c(GL_LINE_STRIP, scalar(@tetra_inds), GL_UNSIGNED_INT, 0);
  glDisableClientState(GL_VERTEX_ARRAY);
  glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
  glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
}

sub display {
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

glDeleteBuffersARB_p($TetraVertObjID) if $TetraVertObjID;
glDeleteBuffersARB_p($TetraIndObjID) if $TetraIndObjID;
