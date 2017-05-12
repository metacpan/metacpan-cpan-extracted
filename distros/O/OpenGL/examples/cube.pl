#!/usr/local/bin/perl
#
#       cube
#
#  Draws a 3-D cube, viewed with perspective, stretched 
#  along the y-axis.
#  Adapted from "cube.c", chapter 3, listing 3-1,
#  page 70, OpenGL Programming Guide 
#

BEGIN{ unshift(@INC,"../blib"); }  # in case OpenGL is built but not installed
BEGIN{ unshift(@INC,"../blib/arch"); } # 5.002 gamma needs this
BEGIN{ unshift(@INC,"../blib/lib");  } # 5.002 gamma needs this
use OpenGL;
 
sub wirecube{
    # adapted from libaux
    local($s) = @_;
    local(@x,@y,@z,@f);
    local($i,$j,$k);
    $s = $s/2.0;
    @x=(-$s,-$s,-$s,-$s,$s,$s,$s,$s);
    @y=(-$s,-$s,$s,$s,-$s,-$s,$s,$s);
    @z=(-$s,$s,$s,-$s,-$s,$s,$s,-$s);
    @f=( 
	0, 1, 2, 3,
	3, 2, 6, 7,
	7, 6, 5, 4,
	4, 5, 1, 0,
	5, 6, 2, 1,
	7, 4, 0, 3,
	);
    for($i=0;$i<6;$i++){
        glBegin(GL_LINE_LOOP);
	for($j=0;$j<4;$j++){
		$k=$f[$i*4+$j];
		glVertex3d($x[$k],$y[$k],$z[$k]);
	}
        glEnd();
    }
}
sub display{
    glClear(GL_COLOR_BUFFER_BIT);
    glColor3f(1.0, 1.0, 1.0);
    glLoadIdentity();	#  clear the matrix
    glTranslatef(0.0, 0.0, -5.0);	#  viewing transformation
    glScalef(1.0, 2.0, 1.0);	#  modeling transformation
    wirecube(1.0);
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
glShadeModel(GL_FLAT);
myReshape();
display();

glpMainLoop;

