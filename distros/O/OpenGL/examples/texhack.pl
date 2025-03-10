#!/usr/local/bin/perl
#
#          texhack
#
#  This program demonstrates texture mapping  
#  An image file (stan.ppm) is read in as the texture
#  by using the glReadTex() function that was
#  created for this OpenGL perl module.
#  This example was implemented before "texture"
#  which calls glTexImage2D directly with a pack()-ed 
#  thing of bytes.
#  The file format must be full color ascii ppm like
#  what is outputted from the image program xv.
#

BEGIN{ unshift(@INC,"../blib"); }  # in case OpenGL is built but not installed
BEGIN{ unshift(@INC,"../blib/arch"); } # 5.002 gamma needs this
BEGIN{ unshift(@INC,"../blib/lib"); } # 5.002 gamma needs this
use OpenGL;
 
$spin=0.0;

sub myReshape {
    # glViewport(0, 0, w, h);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(60.0, 1.0 , 1.0, 30.0);

    glMatrixMode(GL_MODELVIEW);
 }

sub display{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity ();
    glTranslatef(0.0, 0.0, -2.6);

    glPushMatrix();
    glRotatef($spin,0,1,0);
    glRotatef($spin,0,0,1);
    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 1.0); glVertex3f(-1.0, -1.0, 0.0);
    glTexCoord2f(0.0, 0.0); glVertex3f(-1.0, 1.0, 0.0);
    glTexCoord2f(1.0, 0.0); glVertex3f(1.0, 1.0, 0.0);
    glTexCoord2f(1.0, 1.0); glVertex3f(1.0, -1.0, 0.0);

    glPopMatrix();
    glEnd();
    glFlush();
    glXSwapBuffers();
}

glpOpenWindow(width=>200, height=>200, attributes=>[GLX_RGBA,GLX_DOUBLEBUFFER]);
glClearColor(0,0,0,1);
glColor3f (1.0, 1.0, 1.0);
glShadeModel (GL_FLAT);
myReshape();
 
glEnable(GL_DEPTH_TEST);
glDepthFunc(GL_LESS);

glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
$file = "stan.ppm";
-r $file or $file = "examples/$file";
glpReadTex($file);
glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
#glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
#glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
glEnable(GL_TEXTURE_2D);

OpenGL::glFogfv_p(GL_FOG_COLOR,0,0,0,1);
glFogi(GL_FOG_MODE,GL_LINEAR);
glFogf(GL_FOG_START,2.8);
glFogf(GL_FOG_END,3.8);
glEnable(GL_FOG);


while($spin < 100000.0){$spin=$spin+1.0;display; }

