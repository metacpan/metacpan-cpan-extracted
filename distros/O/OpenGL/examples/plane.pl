#!/usr/local/bin/perl
#
#           plane
# This program demonstrates the use of local versus 
# infinite lighting on a flat plane.
# Adapted from book "OpenGL Programming Guide"
#

BEGIN{ unshift(@INC,"../blib"); }  # in case OpenGL is built but not installed
BEGIN{ unshift(@INC,"../blib/arch"); } # 5.002 gamma needs this
BEGIN{ unshift(@INC,"../blib/lib");  } # 5.002 gamma needs this
use OpenGL;



#  Initialize material property, light source, and lighting model.
sub myinit{
    #   mat_specular and mat_shininess are NOT default values
    # Its important not to make a mistake on the packing
    # there's no type checking for C pointer arguments	
    $mat_ambient = pack("f4", 0.0, 0.0, 0.0, 1.0 );
    $mat_diffuse = pack("f4", 0.4, 0.4, 0.4, 1.0 );
    $mat_specular = pack("f4", 1.0, 1.0, 1.0, 1.0 );
    $mat_shininess =  15.0 ;

    $light_ambient = pack("f4", 0.0, 0.0, 0.0, 1.0 );
    $light_diffuse = pack("f4", 1.0, 1.0, 1.0, 1.0 );
    $light_specular = pack("f4", 1.0, 1.0, 1.0, 1.0 );
    $lmodel_ambient = pack("f4", 0.2, 0.2, 0.2, 1.0 );

    glMaterialfv(GL_FRONT, GL_AMBIENT, $mat_ambient);
    glMaterialfv(GL_FRONT, GL_DIFFUSE, $mat_diffuse);
    glMaterialfv(GL_FRONT, GL_SPECULAR, $mat_specular);
    glMaterialf(GL_FRONT, GL_SHININESS, $mat_shininess);
    glLightfv(GL_LIGHT0, GL_AMBIENT, $light_ambient);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, $light_diffuse);
    glLightfv(GL_LIGHT0, GL_SPECULAR, $light_specular);
    glLightModelfv(GL_LIGHT_MODEL_AMBIENT, $lmodel_ambient);

    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glDepthFunc(GL_LESS);
    glEnable(GL_DEPTH_TEST);
}

sub drawPlane {
    glBegin (GL_QUADS);
    glNormal3f (0.0, 0.0, 1.0);
    glVertex3f (-1.0, -1.0, 0.0);
    glVertex3f (0.0, -1.0, 0.0);
    glVertex3f (0.0, 0.0, 0.0);
    glVertex3f (-1.0, 0.0, 0.0);

    glNormal3f (0.0, 0.0, 1.0);
    glVertex3f (0.0, -1.0, 0.0);
    glVertex3f (1.0, -1.0, 0.0);
    glVertex3f (1.0, 0.0, 0.0);
    glVertex3f (0.0, 0.0, 0.0);

    glNormal3f (0.0, 0.0, 1.0);
    glVertex3f (0.0, 0.0, 0.0);
    glVertex3f (1.0, 0.0, 0.0);
    glVertex3f (1.0, 1.0, 0.0);
    glVertex3f (0.0, 1.0, 0.0);

    glNormal3f (0.0, 0.0, 1.0);
    glVertex3f (0.0, 0.0, 0.0);
    glVertex3f (0.0, 1.0, 0.0);
    glVertex3f (-1.0, 1.0, 0.0);
    glVertex3f (-1.0, 0.0, 0.0);
    glEnd();
}

sub display {
    $infinite_light = pack("f4", 1.0, 1.0, 1.0, 0.0 );
    $local_light  = pack("f4", 1.0, 1.0, 1.0, 1.0 );

    glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glPushMatrix ();
    glTranslatef (-1.5, 0.0, 0.0);
    glLightfv (GL_LIGHT0, GL_POSITION, $infinite_light);
    drawPlane ();
    glPopMatrix ();

    glPushMatrix ();
    glTranslatef (1.5, 0.0, 0.0);
    glLightfv (GL_LIGHT0, GL_POSITION, $local_light);
    drawPlane ();
    glPopMatrix ();
    glpFlush ();
}

sub myReshape{
    # glViewport (0, 0, w, h);
    glMatrixMode (GL_PROJECTION);
    glLoadIdentity ();
    glOrtho (-3.0, 3.0, -3.0,  3.0, -10.0, 10.0);
    glMatrixMode (GL_MODELVIEW);
}

# use optional 3rd argument to glpOpenWindow to indicate
# what is needed for the visual just rgb (no double buffer).
glpOpenWindow;
myinit();
myReshape;
display;

glpMainLoop;
