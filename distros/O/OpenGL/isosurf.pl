#!/usr/bin/perl -w

use OpenGL qw(:all);

$speed_test = GL_FALSE;
$use_vertex_arrays = GL_TRUE;

$doubleBuffer = GL_TRUE;

$smooth = GL_TRUE;
$lighting = GL_TRUE;
$light0 = GL_TRUE;
$light1 = GL_TRUE;

$MAXVERTS = 10000;

$verts = new OpenGL::Array $MAXVERTS * 3, GL_FLOAT;
$norms = new OpenGL::Array $MAXVERTS * 3, GL_FLOAT;
$numverts = 0;

$xrot=0;
$yrot=0;

sub read_surface_dat {
	my ($filename) = @_;
	
	open(F, "<$filename") || die "couldn't read $filename\n";
	
	$numverts = 0;
	while ($numverts < $MAXVERTS and defined($_ = <F>)) {
		chop;
		@d = split(/\s+/, $_);
		$verts->assign($numverts*3, @d[0..2]);
		$norms->assign($numverts*3, @d[3..5]);
		$numverts++;
	}
	
	$numverts--;
	
	printf "%d vertices, %d triangles\n", $numverts, $numverts-2;
	
	close(F);
}

sub read_surface_bin {
	my ($filename) = @_;
	
	open(F, "<$filename") || die "couldn't read $filename\n";
	binmode(F);
	$numverts = 0;
	while ($numverts < $MAXVERTS and read(F, $_, 12)==12) {
		@d = map(($_-32000) / 10000 , unpack("nnnnnn", $_));
		$verts->assign($numverts*3, @d[0..2]);
		$norms->assign($numverts*3, @d[3..5]);
		$numverts++;
	}
	
	$numverts--;
	
	printf "%d vertices, %d triangles\n", $numverts, $numverts-2;
	
	close(F);
}

sub draw_surface {
   my ($i);
   
#   glDrawArrays(GL_TRIANGLE_STRIP, 0, $numverts);

   if ($use_vertex_arrays) {
      glDrawArraysEXT( GL_TRIANGLE_STRIP, 0, $numverts );
   }
   else {
      glBegin( GL_TRIANGLE_STRIP );
      for ($i=0;$i<$numverts;$i++) {
         glNormal3d( $norms->retrieve($i*3, 3) );
         glVertex3d( $verts->retrieve($i*3, 3) );
      }
      glEnd();
  }
}

sub draw1 {

    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glPushMatrix();
    glRotated( $yrot, 0.0, 1.0, 0.0 );
    glRotated( $xrot, 1.0, 0.0, 0.0 );

    draw_surface();

    glPopMatrix();

    glFlush();
    if ($doubleBuffer) {
	glutSwapBuffers();
    }
}


sub Draw {
   if ($speed_test) {
      for ($xrot=0.0;$xrot<=360.0;$xrot+=10.0) {
	 draw1();
      }
      MyExit(0);
   }
   else {
      draw1();
   }
}

sub InitMaterials {

	my(@ambient) = (0.1, 0.1, 0.1, 1.0);
    my(@diffuse) = (0.5, 1.0, 1.0, 1.0);
    my (@position0) = (0.0, 0.0, 20.0, 0.0);
    my (@position1) = (0.0, 0.0, -20.0, 0.0);
    my (@front_mat_shininess) = (60.0);
    my (@front_mat_specular) = (0.2, 0.2, 0.2, 1.0);
    my (@front_mat_diffuse) = (0.5, 0.28, 0.38, 1.0);
#    /*
#    my (@back_mat_shininess) = (60.0);
#    my (@back_mat_specular) = (0.5, 0.5, 0.2, 1.0);
#    my (@back_mat_diffuse) = (1.0, 1.0, 0.2, 1.0);
#    */
    my (@lmodel_ambient) = (1.0, 1.0, 1.0, 1.0);
    my (@lmodel_twoside) = (GL_FALSE);

    glLightfv_p(GL_LIGHT0, GL_AMBIENT, @ambient);
    glLightfv_p(GL_LIGHT0, GL_DIFFUSE, @diffuse);
    glLightfv_p(GL_LIGHT0, GL_POSITION, @position0);
    glEnable(GL_LIGHT0);
    
    glLightfv_p(GL_LIGHT1, GL_AMBIENT, @ambient);
    glLightfv_p(GL_LIGHT1, GL_DIFFUSE, @diffuse);
    glLightfv_p(GL_LIGHT1, GL_POSITION, @position1);
    glEnable(GL_LIGHT1);
    
    glLightModelfv_p(GL_LIGHT_MODEL_AMBIENT, @lmodel_ambient);
    glLightModelfv_p(GL_LIGHT_MODEL_TWO_SIDE, @lmodel_twoside);
    glEnable(GL_LIGHTING);

    glMaterialfv_p(GL_FRONT_AND_BACK, GL_SHININESS, @front_mat_shininess);
    glMaterialfv_p(GL_FRONT_AND_BACK, GL_SPECULAR, @front_mat_specular);
    glMaterialfv_p(GL_FRONT_AND_BACK, GL_DIFFUSE, @front_mat_diffuse);
}

sub Init {

   glClearColor(0.0, 0.0, 0.0, 0.0);

   glShadeModel(GL_SMOOTH);
   glEnable(GL_DEPTH_TEST);

   InitMaterials();

   glMatrixMode(GL_PROJECTION);
   glLoadIdentity();
   glFrustum( -1.0, 1.0, -1.0, 1.0, 5, 25 );

   glMatrixMode(GL_MODELVIEW);
   glLoadIdentity();
   glTranslated( 0.0, 0.0, -6.0 );
   
#   glVertexPointer_a( 3, GL_FLOAT, 0, $verts );
#   glNormalPointer_a( GL_FLOAT, 0, $norms );
#   glEnable( GL_VERTEX_ARRAY );
#   glEnable( GL_NORMAL_ARRAY );
   

   if ($use_vertex_arrays) {
      glVertexPointerEXT_c( 3, GL_FLOAT, 0, $numverts, $verts->ptr );
      glNormalPointerEXT_c( GL_FLOAT, 0, $numverts, $norms->ptr );
      glEnable( GL_VERTEX_ARRAY_EXT );
      glEnable( GL_NORMAL_ARRAY_EXT );
   }
}

sub Reshape {
	my ($width, $height) = @_;

    glViewport(0, 0, $width, $height);
}


sub Key {
	my ($key, $x, $y ) = @_;
	
	if ($key == 27 or $key == ord 'q' or $key == ord 'Q') {
		MyExit();
	} elsif ($key == ord('s')) {
		$smooth = !$smooth;
		if ($smooth) {
		    glShadeModel(GL_SMOOTH);
		} else {
		    glShadeModel(GL_FLAT);
		}
	} elsif ($key == ord('0')) {
		$light0 = !$light0;
		if ($light0) {
		    glEnable(GL_LIGHT0);
		} else {
		    glDisable(GL_LIGHT0);
		}
	} elsif ($key == ord('1')) {
		$light1 = !$light1;
		if ($light1) {
		    glEnable(GL_LIGHT1);
		} else {
		    glDisable(GL_LIGHT1);
		}
	} elsif ($key == ord('l')) {
		$lighting = !$lighting;
		if ($lighting) {
		    glEnable(GL_LIGHTING);
		} else {
		    glDisable(GL_LIGHTING);
		}
   } else {
   	return;
   }
   glutPostRedisplay();
}

sub SpecialKey {
	my ($key, $x, $y ) = @_;

	if  ($key ==  GLUT_KEY_LEFT) {
		$yrot -= 15.0;
	} elsif ($key == GLUT_KEY_RIGHT) {
		$yrot += 15.0;
	} elsif ($key == GLUT_KEY_UP) {
		$xrot += 15.0;
	} elsif ($key == GLUT_KEY_DOWN) {
		$xrot -= 15.0;
    } else {
    	return;
    }
    glutPostRedisplay();
}


#sub  Args(int argc, char **argv)
#{
#   GLint i;
#
#   for (i = 1; i < argc; i++) {
#      if (strcmp(argv[i], "-sb") == 0) {
#         doubleBuffer = GL_FALSE;
#      }
#      else if (strcmp(argv[i], "-db") == 0) {
#         doubleBuffer = GL_TRUE;
#      }
#      else if (strcmp(argv[i], "-speed") == 0) {
#         speed_test = GL_TRUE;
#         doubleBuffer = GL_TRUE;
#      }
#      else if (strcmp(argv[i], "-va") == 0) {
#         use_vertex_arrays = GL_TRUE;
#      }
#      else {
#         printf("%s (Bad option).\n", argv[i]);
#         return GL_FALSE;
#      }
#   }
#
#   return GL_TRUE;
#}

my $WindowId;

#int main(int argc, char **argv)
#{
#   GLenum type;
#   char *extensions;

   read_surface_bin( "isosurf.bin" );

#   if (Args(argc, argv) == GL_FALSE) {
#      exit(0);
#   }

   glutInit();
   glutInitWindowPosition(0, 0);
   glutInitWindowSize(400, 400);
   
   $type = GLUT_DEPTH;
   $type |= GLUT_RGB;
   $type |= ($doubleBuffer) ? GLUT_DOUBLE : GLUT_SINGLE;
   glutInitDisplayMode($type);

   if (($WindowId = glutCreateWindow("Isosurface")) <= 0) {
      exit(0);
   }

#   /* Make sure server supports the vertex array extension */
#    $extensions = glGetString( GL_EXTENSIONS );
#    if ($extensions !~ /\bGL_EXT_vertex_array\b/
# 	or OpenGL::_have_glp and not OpenGL::_have_glx and 0) { # OS/2 reports wrong
#       $use_vertex_arrays = GL_FALSE;
#    }
#    print "Extensions: '$extensions'.\n";
   if (defined &OpenGL::glVertexPointerEXT_c) {
     print "Using Vertex Array...\n";
   } else {
     print "No Vertex Array extension found, using a slow method...\n";
     $use_vertex_arrays = 0;
   }

   Init();

   glutReshapeFunc(\&Reshape);
   glutKeyboardFunc(\&Key);
   glutSpecialFunc(\&SpecialKey);
   glutDisplayFunc(\&Draw);
   glutMainLoop();

# This leaves GLUT running (at least under OS/2...).

#sub MyExit {
#  exit shift if $WindowId <= 0;
#  glutDestroyWindow($WindowId);
#  warn "Exiting...\n";
#}

sub MyExit { exit }		# Segfaults under OS/2...
