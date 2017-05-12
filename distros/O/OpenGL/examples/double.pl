#!/usr/local/bin/perl
#
#           double
#
#  This program demonstrates double buffering for 
#  flicker-free animation.  
#  Adapted from "double", chapter 1, listing 1-3,
#  page 17, OpenGL Programming Guide 

BEGIN{ unshift(@INC,"../blib"); }  # in case OpenGL is built but not installed
BEGIN{ unshift(@INC,"../blib/arch"); } # 5.002 gamma needs this
BEGIN{ unshift(@INC,"../blib/lib");  } # 5.002 gamma needs this
use OpenGL;
 
$spin = 0.0;


sub myReshape {
    # glViewport(0, 0, w, h);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho (-50.0, 50.0, -50.0,50.0,-1.0,1.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity ();
}

sub display{
    glClear(GL_COLOR_BUFFER_BIT);

    glPushMatrix();
    glRotatef($spin, 0.0, 0.0, 1.0);
    ($x,$y) = glpXQueryPointer;
    glRectf(-25.0, -25.0, 25+$x/10, 25+$y/10);
    glPopMatrix();

    glFlush();
    glXSwapBuffers;
}
$increment=2.0;
sub spinDisplay {
    $spin = $spin + $increment;
    if ($spin > 360.0) {
	$spin = $spin - 360.0;
    }
    display();
}

glpOpenWindow(attributes=>[GLX_RGBA,GLX_DOUBLEBUFFER]);
glClearColor(0,0,0,1);
glColor3f (1.0, 1.0, 1.0);
glShadeModel (GL_FLAT);
myReshape();
$cb{&ConfigureNotify} = sub { local($e,$w,$h)=@_;glViewport(0,0,$w,$h);
			 # print "viewport $w,$h\n";
			};
$cb{&KeyPress} = sub { # print "@_[1] ",ord(@_[1])," keypress @_\n";
		      local($ss); &$ss(@_[1]) if ($ss=$kcb{@_[1]}); };
$kcb{'q'} = $kcb{'Q'} = $kcb{"\033"} = sub{ print "Good-Bye\n"; exit 0;};
sub setincrement{$increment = $_[0];}
foreach $i (0..9){
	$kcb{"$i"}=\&setincrement;
}
#print "cn=",&ConfigureNotify,"\n";
#print "kn=",KeyPress,"\n";

while(1) {
	spinDisplay();
	while($p=XPending) {
		#print $p,"\n"; 
		@e=&glpXNextEvent;
		#print("e=@e\n");
		&$s(@e) if($s=$cb{$e[0]});
		#print "doncb\n" if ($s);
	}
}
