#!/usr/bin/perl -w

use strict;
use Time::HiRes qw(sleep);
use OpenGL ':old', ':glutfunctions', ':glutconstants';

my $where = (@ARGV ? 'far away' : 'near Earth');
print "Camera position: $where.\n";
print "Give arguments to position camera far away.\n";

my $field_of_view = (@ARGV ? 20 : 100); # Degrees
my $minviewdist = 0.1;
my $maxviewdist = 1000;

my $mercury = 0;
my $venus = 0;
my $earth = 0;
my $earthMoon = 0;
my $earthspin = 0;
my $mars = 0;
my $jupiter = 230;		# Make them visible
my $jups1 = 0;
my $jups2 = 0;
my $jups3 = 0;
my $jups4 = 0;
my $saturn = 250;		# Make them visible

sub resizeHandler {		# Not auto yet
  my ($wind_w, $wind_h) = @_;
  
  glMatrixMode( GL_PROJECTION );
   glLoadIdentity();
   gluPerspective( $field_of_view, $wind_w/$wind_h,
		   $minviewdist, $maxviewdist );
  glMatrixMode( GL_MODELVIEW );
}

sub display {
  # clear the canvas
  glClearColor(0,0,0,1);
  glDrawBuffer(GL_FRONT_AND_BACK);
  glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
  glDrawBuffer(GL_BACK);

  glLoadIdentity();

  if (@ARGV) {
    # move the squares back a bit
    glTranslatef( 0, 0, -500 );
    # and add a tilt
    glRotatef(-70, 1,0,0);
  } else {
    # place viewpoint on the surface of the planet
    glRotatef(30, 1,0,0);
    glTranslatef( 0, -5, 2 );
    glRotatef(-$earthspin, 0,1,0);
    glTranslatef( 0, 0, -60 );
    glRotatef(-90, 1,0,0);
    glRotatef(90-$earth, 0,0,1);
  }

  # Sun light
  glLightfv(GL_LIGHT0, GL_POSITION, pack "f4", 0, 0, 0, 1);
  #glLightfv(GL_LIGHT1, GL_DIFFUSE,  pack "f4", 1, 1, 1, 1);
  #glLightfv(GL_LIGHT0, GL_DIFFUSE,  pack "f4", 0, 0, 0, 1);
  # Same for specular?

  # Moon light

  glPushMatrix();

  # Position the moon
  glRotatef($earth,0,0,1);
  glTranslatef( -60, 0, 0 );
  glRotatef($earthMoon,0,0,1);
  glTranslatef( -10, 0, 0 );
  glLightfv(GL_LIGHT1, GL_POSITION, pack "f4", 0, 0, 0, 1);
  my $moon_bright = 0.1*(1 + cos($earthMoon*3.1415926/180));
  glLightfv(GL_LIGHT1, GL_AMBIENT, 
	    pack "f4", $moon_bright, $moon_bright, $moon_bright, 1);
  
  glPopMatrix();

  # Sun
  # glColor3f(1,1,1);
  glMaterialfv( GL_FRONT, GL_EMISSION, pack 'f4', 1, 1, 0, 1);
  glutSolidSphere(20,10,10);
  glMaterialfv( GL_FRONT, GL_EMISSION, pack 'f4', 0, 0, 0, 1);
  
  glPushMatrix();

  # Position the mercury
  glRotatef($mercury,0,0,1);
  glTranslatef( -30, 0, 0 );
  glColor3f(0.6, 0.6, 0.6);
  glutSolidSphere(2,10,10);
  
  glPopMatrix();
  
  glPushMatrix();

  # Position the venus
  glRotatef($venus,0,0,1);
  glTranslatef( -40, 0, 0 );
  glColor3f(0,1,0);
  glutSolidSphere(5,10,10);
  
  glPopMatrix();
  
  glPushMatrix();

  # Position the earth
  glRotatef($earth,0,0,1);
  glTranslatef( -60, 0, 0 );
  glColor3f(0,0,1);

  glPushMatrix();

  # Rotate the planet earth
  glRotatef($earthspin,0,0,1);
  
  glEnable( GL_LIGHT1 );
  glutSolidSphere(5,10,10);
  glDisable( GL_LIGHT1 );

  glPopMatrix();

  
  # Position the earth's moon
  glRotatef($earthMoon,0,0,1);
  glTranslatef( -10, 0, 0 );
  glColor3f(0.5,0.5,0.5);
  glutSolidSphere(1,10,10);

  glPopMatrix();
  
  glPushMatrix();

  # Position the mars
  glRotatef($mars,0,0,1);
  glTranslatef( -80, 0, 0 );
  glColor3f(1,0,0);
  glutSolidSphere(4,10,10);
  
  glPopMatrix();
  
  glPushMatrix();

  # Position the jupiter
  glRotatef($jupiter,0,0,1);
  glTranslatef( -120, 0, 0 );
  glColor3f(0.6,0.6,0.6);
  glutSolidSphere(9,10,10);

  glPushMatrix();

  # Position the jup's moon1
  glRotatef($jups1,0,0,1);
  glTranslatef( -6, 0, 0 );
  glColor3f(0.5,0.5,0.5);
  glutSolidSphere(1,10,10);
  
  glPopMatrix();
  
  glPushMatrix();

  # Position the jup's moon2
  glRotatef($jups2,0,0,1);
  glTranslatef( -8, 0, 0 );
  glColor3f(0.5,0.5,0.5);
  glutSolidSphere(1,10,10);
  
  glPopMatrix();
  
  glPushMatrix();

  # Position the jup's moon3
  glRotatef($jups3,0,0,1);
  glTranslatef( -10, 0, 0 );
  glColor3f(0.5,0.5,0.5);
  glutSolidSphere(1,10,10);
  
  glPopMatrix();
  
  glPushMatrix();

  # Position the jup's moon4
  glRotatef($jups4,0,0,1);
  glTranslatef( -12, 0, 0 );
  glColor3f(0.5,0.5,0.5);
  glutSolidSphere(1,10,10);
  
  glPopMatrix();
  
  glPopMatrix();
  
  glPushMatrix();

  # Position the saturn
  glRotatef($saturn,0,0,1);
  glTranslatef( -150, 0, 0 );
  glColor3f(0.5,0.5,0.5);
  glutSolidSphere(8,10,10);

  glRotatef(-$saturn,0,0,1);
  glRotatef(14, 0.707, -0.707, 0); # What is the actual tilt?
  glScalef(1,1,0.2);		# Giving smaller values makes it white?!
  eval {glutSolidTorus(4.5,13,10,10)};
  
  glPopMatrix();
  
  glPopMatrix();
  
  glutSwapBuffers();
}

glutInit();
glutInitDisplayMode( GLUT_DOUBLE | GLUT_DEPTH );
glutCreateWindow('Planets Example');
glutDisplayFunc(\&display);
glutReshapeFunc(\&resizeHandler);

#glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
glEnable( GL_DEPTH_TEST );
glEnable( GL_LIGHTING );
glEnable( GL_LIGHT0 );
glEnable( GL_COLOR_MATERIAL );
glLightModelfv( GL_LIGHT_MODEL_AMBIENT, pack 'f4', 0.1, 0.1, 0.1, 1);


while ( sleep(0.1) ) {
  glutMainLoopEvent();
  $mercury += 1/0.24;
  $mercury -= 360 if $mercury >= 360;
  
  $venus += 1/0.62;
  $venus -= 360 if $venus >= 360;
  
  $earthMoon += 12.36;		# Relative to sun-earth line
  $earthMoon -= 360 if $earthMoon >= 360;
  
  $earthspin += 3.65;		# 1/100 of real
  $earthspin -= 360 if $earthspin >= 360;
  
  $earth += 1;
  $earth -= 360 if $earth >= 360;
  
  $venus += 1/0.62;
  $venus -= 360 if $venus >= 360;
  
  $mars += 1/1.88;			# Wrong
  $mars -= 360 if $mars >= 360;
  
  $jupiter += 1/11.86;
  $jupiter -= 360 if $jupiter >= 360;
  
  $jups1 += -1/11.86 + 365.2/1.77;
  $jups1 -= 360 if $jups1 >= 360;
  
  $jups2 += -1/11.86 + 365.2/3.55;
  $jups2 -= 360 if $jups2 >= 360;
  
  $jups3 += -1/11.86 + 365.2/7.16;
  $jups3 -= 360 if $jups3 >= 360;
  
  $jups4 += -1/11.86 + 365.2/16.69;
  $jups4 -= 360 if $jups4 >= 360;
  
  $saturn += 1/29.46;
  $saturn -= 360 if $saturn >= 360;
  
  glutPostRedisplay();
}
