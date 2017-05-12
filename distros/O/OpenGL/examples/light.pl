#!/usr/local/bin/perl
#
#          light
#
#  This program demonstrates the use of the OpenGL lighting model.  
#  A icosahedron is drawn using a grey material characteristic. 
#  A single light source illuminates the object.
#  Example adapted from light.c.

BEGIN{ unshift(@INC,"../blib"); }  # in case OpenGL is built but not installed
BEGIN{ unshift(@INC,"../blib/arch"); } # 5.002 gamma needs this
BEGIN{ unshift(@INC,"../blib/lib");  } # 5.002 gamma needs this
use OpenGL;

$use_lighting=1;
$use_frame=1;

sub icosahedron{
    # from OpenGL Programming Guide page 56
    $x=0.525731112119133606;
    $z=0.850650808352039932;

    $v=[
	[-$x,   0,  $z],
	[ $x,   0,  $z],
	[-$x,   0, -$z],
	[ $x,   0, -$z],
	[  0,  $z,  $x],
	[  0,  $z, -$x],
	[  0, -$z,  $x],
	[  0, -$z, -$x],
	[ $z,  $x,   0],
	[-$z,  $x,   0],
	[ $z, -$x,   0],
	[-$z, -$x,   0],
       ];
    $t=[
	[0,4,1],  	[0, 9, 4],
    	[9, 5, 4],    	[4, 5, 8],
    	[4, 8, 1],    	[8, 10, 1],
    	[8, 3, 10],    	[5, 3, 8],
    	[5, 2, 3],    	[2, 7, 3],
    	[7, 10, 3],    	[7, 6, 10],
    	[7, 11, 6],    	[11, 0, 6],
    	[0, 1, 6],    	[6, 1, 10],
    	[9, 0, 11],    	[9, 11, 2],
    	[9, 2, 5],    	[7, 2, 11],
       ];
    for($i=0;$i<20;$i++) {
	glBegin(GL_POLYGON);
	    for($j=0;$j<3;$j++) {
		$use_lighting || glColor3f(0,$i/19.0,$j/2.0);
		glNormal3f( $v->[$t->[$i][$j]][0],
				$v->[$t->[$i][$j]][1],
				$v->[$t->[$i][$j]][2]);
		glVertex3f( $v->[$t->[$i][$j]][0],
				$v->[$t->[$i][$j]][1],
				$v->[$t->[$i][$j]][2]);
	    }
	glEnd();
	if( $use_frame){
	    glPushAttrib(GL_ALL_ATTRIB_BITS);
	    glDisable(GL_LIGHTING);
	    glColor3f(1,0,0);
	    glBegin(GL_LINE_LOOP);
	        for($j=0;$j<3;$j++) {
	    	glVertex3f( 	1.01 * $v->[$t->[$i][$j]][0],
	    			1.01 * $v->[$t->[$i][$j]][1],
	    			1.01 * $v->[$t->[$i][$j]][2]);
	        }
	    glEnd();
	    glPopAttrib();
	}
    }
}

sub myinit{
    # Initialize material property, light source, lighting model, 
    # and depth buffer.
    @mat_specular = ( 1.0, 1.0, 0.0, 1.0 );
    @mat_diffuse  = ( 0.0, 1.0, 1.0, 1.0 );
    @light_position = ( 1.0, 1.0, 1.0, 0.0 );

    glMaterialfv(GL_FRONT, GL_DIFFUSE, pack("f4",@mat_diffuse));
    glMaterialfv(GL_FRONT, GL_SPECULAR, pack("f4",@mat_specular));
    glMaterialf(GL_FRONT, GL_SHININESS, 10);
    glLightfv(GL_LIGHT0, GL_POSITION, pack("f4",@light_position));

    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glDepthFunc(GL_LESS);
    glEnable(GL_DEPTH_TEST);
} 

sub display {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glPushMatrix();
    glRotatef(23*sin($spin*3.14/180),1,0,0);
    glRotatef($spin,0,1,0);
    icosahedron;
    glPopMatrix();

    glFlush();
    glXSwapBuffers();
}

sub myReshape {
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-1.5, 1.5, -1.5, 1.5, -10.0, 10.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}
 
glpOpenWindow(width=>300,height=>300,
	attributes=> [GLX_DOUBLEBUFFER,GLX_RGBA,
		GLX_DEPTH_SIZE,16,
		GLX_RED_SIZE,1,
		GLX_GREEN_SIZE,1,
		GLX_BLUE_SIZE,1]);

$use_lighting && myinit();
myReshape();
glEnable(GL_DEPTH_TEST);
glRotatef(0.12,1,0,0);

while(1){$spin+=1;display;}
