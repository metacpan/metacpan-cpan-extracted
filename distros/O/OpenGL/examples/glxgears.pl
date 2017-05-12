#!/usr/bin/perl

# 
# Ported by: Brian Medley <freesoftware@bmedley.org>
# 
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself. 
# 
#

use strict;
use warnings;

use OpenGL qw/ :all /;
use OpenGL::Config;
use Math::Trig;

my ($gear1, $gear2, $gear3);
my $angle = 0;
my $view_rotx = 20.0; 
my $view_roty = 30.0;
my $view_rotz = 0.0;

# Window and texture IDs, window width and height.
my $Window_ID;
my $Window_Width = 640;
my $Window_Height = 480;

use constant PROGRAM_TITLE => "glxgears.pl";
use constant M_PI => 3.14159265;

# Inits OpenGL.  Calls our own init function, then passes control onto OpenGL.
MAIN:
{
	glutInit();

	print("CTRL-C to quit\n");

	# To see OpenGL drawing, take out the GLUT_DOUBLE request.
	glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH | GLUT_ALPHA);
	# glutInitDisplayMode(GLUT_RGBA | GLUT_DEPTH | GLUT_ALPHA);

 	# skip these MODE checks on win32, they don't work
	if ($^O ne 'MSWin32' and $OpenGL::Config->{DEFINE} !~ /-DHAVE_W32API/) {

	   if (not glutGet(GLUT_DISPLAY_MODE_POSSIBLE))
	   {
	      warn "glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH | GLUT_ALPHA) not possible";
	      warn "...trying without GLUT_ALPHA";
	      # try without GLUT_ALPHA
	      glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH);
	      if (not glutGet(GLUT_DISPLAY_MODE_POSSIBLE))
	      {
		 warn "glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH) not possible, exiting quietly";
		 exit 0;
	      }
	   }
	}

	glutInitWindowSize($Window_Width, $Window_Height);
	$Window_ID = glutCreateWindow( PROGRAM_TITLE );

	# Register the callback function to do the drawing.
	glutDisplayFunc(\&draw);

	# If there's nothing to do, draw.
	glutIdleFunc(\&draw);

	# It's a good idea to know when our window's resized.
	glutReshapeFunc(\&reshape);

	# OK, OpenGL's ready to go.  Let's call our own init function.
	ourInit($Window_Width, $Window_Height);

	glutMainLoop();
	exit(0);
}

sub ourInit
{
  my ($Width, $Height) = @_;

   my @pos = ( 5.0, 5.0, 10.0, 0.0 );
   my @red = ( 0.8, 0.1, 0.0, 1.0 );
   my @green = ( 0.0, 0.8, 0.2, 1.0 );
   my @blue = ( 0.2, 0.2, 1.0, 1.0 );

   glLightfv_p(GL_LIGHT0, GL_POSITION, @pos);
   glEnable(GL_CULL_FACE);
   glEnable(GL_LIGHTING);
   glEnable(GL_LIGHT0);
   glEnable(GL_DEPTH_TEST);

   $gear1 = glGenLists(1);
   glNewList($gear1, GL_COMPILE);
   glMaterialfv_s(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, pack("f4", @red));
   gear(1.0, 4.0, 1.0, 20, 0.7);
   glEndList();

   $gear2 = glGenLists(1);
   glNewList($gear2, GL_COMPILE);
   glMaterialfv_s(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, pack("f4", @green));
   gear(0.5, 2.0, 2.0, 10, 0.7);
   glEndList();

   $gear3 = glGenLists(1);
   glNewList($gear3, GL_COMPILE);
   glMaterialfv_s(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, pack("f4", @blue));
   gear(1.3, 2.0, 0.5, 10, 0.7);
   glEndList();

   glEnable(GL_NORMALIZE);

   reshape($Width, $Height);
}

sub gear
{
   my ($inner_radius, $outer_radius, $width, $teeth, $tooth_depth) = @_;
   my  $i;
   my ($r0, $r1, $r2);
   my ($angle, $da);
   my ($u, $v, $len);

   $r0 = $inner_radius;
   $r1 = $outer_radius - $tooth_depth / 2.0;
   $r2 = $outer_radius + $tooth_depth / 2.0;

   $da = 2.0 * M_PI / $teeth / 4.0;

   glShadeModel(GL_FLAT);

   glNormal3f(0.0, 0.0, 1.0);

   # /* draw front face */
   glBegin(GL_QUAD_STRIP);
   for ($i = 0; $i <= $teeth; $i++) {
      $angle = $i * 2.0 * M_PI / $teeth;
      glVertex3f($r0 * cos($angle), $r0 * sin($angle), $width * 0.5);
      glVertex3f($r1 * cos($angle), $r1 * sin($angle), $width * 0.5);
      if ($i < $teeth) {
         glVertex3f($r0 * cos($angle), $r0 * sin($angle), $width * 0.5);
         glVertex3f($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da),
                    $width * 0.5);
      }
   }
   glEnd();

   # /* draw front sides of teeth */
   glBegin(GL_QUADS);
   $da = 2.0 * M_PI / $teeth / 4.0;
   for ($i = 0; $i < $teeth; $i++) {
      $angle = $i * 2.0 * M_PI / $teeth;

      glVertex3f($r1 * cos($angle), $r1 * sin($angle), $width * 0.5);
      glVertex3f($r2 * cos($angle + $da), $r2 * sin($angle + $da), $width * 0.5);
      glVertex3f($r2 * cos($angle + 2 * $da), $r2 * sin($angle + 2 * $da),
                 $width * 0.5);
      glVertex3f($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da),
                 $width * 0.5);
   }
   glEnd();

   glNormal3f(0.0, 0.0, -1.0);

   # /* draw back face */
   glBegin(GL_QUAD_STRIP);
   for ($i = 0; $i <= $teeth; $i++) {
      $angle = $i * 2.0 * M_PI / $teeth;
      glVertex3f($r1 * cos($angle), $r1 * sin($angle), -$width * 0.5);
      glVertex3f($r0 * cos($angle), $r0 * sin($angle), -$width * 0.5);
      if ($i < $teeth) {
         glVertex3f($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da),
                    -$width * 0.5);
         glVertex3f($r0 * cos($angle), $r0 * sin($angle), -$width * 0.5);
      }
   }
   glEnd();

   # /* draw back sides of teeth */
   glBegin(GL_QUADS);
   $da = 2.0 * M_PI / $teeth / 4.0;
   for ($i = 0; $i < $teeth; $i++) {
      $angle = $i * 2.0 * M_PI / $teeth;

      glVertex3f($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da),
                 -$width * 0.5);
      glVertex3f($r2 * cos($angle + 2 * $da), $r2 * sin($angle + 2 * $da),
                 -$width * 0.5);
      glVertex3f($r2 * cos($angle + $da), $r2 * sin($angle + $da), -$width * 0.5);
      glVertex3f($r1 * cos($angle), $r1 * sin($angle), -$width * 0.5);
   }
   glEnd();

   # /* draw outward faces of teeth */
   glBegin(GL_QUAD_STRIP);
   for ($i = 0; $i < $teeth; $i++) {
      $angle = $i * 2.0 * M_PI / $teeth;

      glVertex3f($r1 * cos($angle), $r1 * sin($angle), $width * 0.5);
      glVertex3f($r1 * cos($angle), $r1 * sin($angle), -$width * 0.5);
      $u = $r2 * cos($angle + $da) - $r1 * cos($angle);
      $v = $r2 * sin($angle + $da) - $r1 * sin($angle);
      $len = sqrt($u * $u + $v * $v);
      $u /= $len;
      $v /= $len;
      glNormal3f($v, -$u, 0.0);
      glVertex3f($r2 * cos($angle + $da), $r2 * sin($angle + $da), $width * 0.5);
      glVertex3f($r2 * cos($angle + $da), $r2 * sin($angle + $da), -$width * 0.5);
      glNormal3f(cos($angle), sin($angle), 0.0);
      glVertex3f($r2 * cos($angle + 2 * $da), $r2 * sin($angle + 2 * $da),
                 $width * 0.5);
      glVertex3f($r2 * cos($angle + 2 * $da), $r2 * sin($angle + 2 * $da),
                 -$width * 0.5);
      $u = $r1 * cos($angle + 3 * $da) - $r2 * cos($angle + 2 * $da);
      $v = $r1 * sin($angle + 3 * $da) - $r2 * sin($angle + 2 * $da);
      glNormal3f($v, -$u, 0.0);
      glVertex3f($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da),
                 $width * 0.5);
      glVertex3f($r1 * cos($angle + 3 * $da), $r1 * sin($angle + 3 * $da),
                 -$width * 0.5);
      glNormal3f(cos($angle), sin($angle), 0.0);
   }

   glVertex3f($r1 * cos(0), $r1 * sin(0), $width * 0.5);
   glVertex3f($r1 * cos(0), $r1 * sin(0), -$width * 0.5);

   glEnd();

   glShadeModel(GL_SMOOTH);

   # /* draw inside radius cylinder */
   glBegin(GL_QUAD_STRIP);
   for ($i = 0; $i <= $teeth; $i++) {
      $angle = $i * 2.0 * M_PI / $teeth;
      glNormal3f(-cos($angle), -sin($angle), 0.0);
      glVertex3f($r0 * cos($angle), $r0 * sin($angle), -$width * 0.5);
      glVertex3f($r0 * cos($angle), $r0 * sin($angle), $width * 0.5);
   }
   glEnd();
}

sub draw
{
   glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

      $angle += 2.0;

   glPushMatrix();
   glRotatef($view_rotx, 1.0, 0.0, 0.0);
   glRotatef($view_roty, 0.0, 1.0, 0.0);
   glRotatef($view_rotz, 0.0, 0.0, 1.0);

   glPushMatrix();
   glTranslatef(-3.0, -2.0, 0.0);
   glRotatef($angle, 0.0, 0.0, 1.0);
   glCallList($gear1);
   glPopMatrix();

   glPushMatrix();
   glTranslatef(3.1, -2.0, 0.0);
   glRotatef(-2.0 * $angle - 9.0, 0.0, 0.0, 1.0);
   glCallList($gear2);
   glPopMatrix();

   glPushMatrix();
   glTranslatef(-3.1, 4.2, 0.0);
   glRotatef(-2.0 * $angle - 25.0, 0.0, 0.0, 1.0);
   glCallList($gear3);
   glPopMatrix();

   glPopMatrix();
   
  # Double-buffer and done
  glutSwapBuffers();
}

sub reshape
{
   my ($width, $height) = @_;

   my $h = $height / $width;

   glViewport(0, 0, $width, $height);
   glMatrixMode(GL_PROJECTION);
   glLoadIdentity();
   glFrustum(-1.0, 1.0, -$h, $h, 5.0, 60.0);
   glMatrixMode(GL_MODELVIEW);
   glLoadIdentity();
   glTranslatef(0.0, 0.0, -40.0);
}
