#         depth
#
# Simple demo showing effect of Z (depth) buffering.
# I saw a similar demo in the MESA distribution.

use OpenGL;

# if you dont ask for a visual with a depth buffer you might not get one
glpOpenWindow(attributes=>[GLX_RGBA,GLX_DEPTH_SIZE,1]);

# enable the important gl feature
glEnable(GL_DEPTH_TEST);
glClearColor(0,0,0,1);
glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
glLoadIdentity;

glOrtho(-1.2,1.2,-1.2,1.2,-1,1);
# draw intersecting triangles
glColor3f(1,0,0);
glBegin(GL_POLYGON);
  glVertex3f(-1,1,0);
  glVertex3f(-1,-1,0);
  glVertex3f(0.9,0,0.8);
glEnd();
glColor3f(0,1,0);
glBegin(GL_POLYGON);
  glVertex3f(1,-1,0);
  glVertex3f(1,1,0);
  glVertex3f(-0.9,0,1);
glEnd();
glpFlush();

glpMainLoop;
