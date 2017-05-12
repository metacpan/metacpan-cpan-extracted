#!/usr/local/bin/perl
#
# simple example taken from listing 1-1 (or 1-2) from OpenGL book
#

BEGIN{ unshift(@INC,"../blib"); }  # in case OpenGL is built but not installed
BEGIN{ unshift(@INC,"../blib/arch"); } # 5.002 gamma needs this
BEGIN{ unshift(@INC,"../blib/lib"); } # 5.002 gamma needs this
use OpenGL;

glpOpenWindow;
glClearColor(0,0,1,1);
glClear(GL_COLOR_BUFFER_BIT);
glOrtho(-1,1,-1,1,-1,1);

glColor3f(1,0,0);
glBegin(GL_POLYGON);
  glVertex2f(-0.5,-0.5);
  glVertex2f(-0.5, 0.5);
  glVertex2f( 0.5, 0.5);
  glVertex2f( 0.5,-0.5);
glEnd();
glpFlush();

print "Program 1-1 Simple, hit Enter in terminal window to quit:\n\n";
glpMainLoop;
