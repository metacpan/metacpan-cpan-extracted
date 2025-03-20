#            smooth
#
# This program demonstrates smooth shading.
# A smooth shaded polygon is drawn in a 2-D projection.
# This example adapted from smooth.c from "OpenGL Programming Guide" 

use OpenGL;

sub triangle{
    glBegin (GL_TRIANGLES);
    glColor3f (1.0, 0.0, 0.0);
    glVertex2f (5.0, 5.0);
    glColor3f (0.0, 1.0, 0.0);
    glVertex2f (25.0, 5.0);
    glColor3f (0.0, 0.0, 1.0);
    glVertex2f (5.0, 25.0);
    glEnd ();
}

glpOpenWindow;
# GL_SMOOTH is actually the default shading model. 
glShadeModel (GL_SMOOTH);
glMatrixMode(GL_PROJECTION);
glLoadIdentity();
gluOrtho2D (0.0, 30.0, 0.0, 30.0);
glMatrixMode(GL_MODELVIEW);

glClear (GL_COLOR_BUFFER_BIT);
triangle ();
glpFlush ();

glpMainLoop;
