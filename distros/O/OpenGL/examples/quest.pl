#!/usr/local/bin/perl 

# simple maze thingy

# in case module not "installed" :
BEGIN{ unshift(@INC,"./blib"); unshift(@INC,"../blib"); }
BEGIN{ unshift(@INC,"../blib/arch"); } # 5.002 gamma needs this
BEGIN{ unshift(@INC,"../blib/lib"); } # 5.002 gamma needs this
use OpenGL;

@walldata = (
	"****************",
	"* *     *      *",
	"* * *** * *    *",
	"* *   * ** * * *",
	"*   * *      * *",
	"********** *** *",
	"*           *  *",
	"* ***** *** ****",
	"* *   *   *    *",
	"*   * *** *    *",
	"* *   *   *  * *",
	"* ***** **** * *",
	"*     *      * *",
	"***** ******** *",
	"*   * *     *  *",
	"* ***   *** ****",
	"*     *   *    *",
	"****************",
	);


$x_size = scalar(@walldata);
$y_size = length($walldata[0]);
($x_size > 3 && $x_size<200) || die "bad data - number of rows $x_size ";
($y_size > 3 && $y_size<200) || die "bad data - number of columns $y_size ";


	for($x=0;$x<$x_size;$x++) {
		($y_size==length($walldata[$x])) || 
		    die "line $x of data ",length($walldata[$x]),"/$y_size chars";
		$walldata[$x] =~ s/ /0/g;
		$walldata[$x] =~ s/\*/1/g;
		my(@ww)=split(//,$walldata[$x]);
		#print "$wall[$x] - @ww -";
		$wall[$x] = \ @ww;
		#print "@{$wall[$x]}\n";
	}
	$s=1;
    	@cx=(0,0,0,0,$s,$s,$s,$s);
    	@cy=(0,0,$s,$s,0,0,$s,$s);
    	@cz=(0,$s,$s,0,0,$s,$s,0);
    	@cf=( 
        	0, 1, 2, 3,
        	3, 2, 6, 7,
        	7, 6, 5, 4,
        	4, 5, 1, 0,
        	5, 6, 2, 1,
        	7, 4, 0, 3,
           );
    @r=(0.5, 0,   0,   0.5, 1.0, 0);
    @g=(0,   0.5, 0,   0.5, 0,   1.0);
    @b=(0,   0,   0.5, 0,   1.0, 1.0);

sub drawwalls {
	local($x,$y,$dl);
	glNewList($dl=glGenLists(1),GL_COMPILE);
	for($x=0;$x<$x_size;$x++) {
		for($y=0;$y<$y_size;$y++) {
			if($wall[$x]->[$y]) {
    				for($i=0;$i<6;$i++){
					if(
					   $i==4 || $i==5 || 
						  ($i==0 && ($x==0  || !($wall[$x-1]->[$y]))) || 
						  ($i==1 && ($y==$y_size-1 || !($wall[$x]->[$y+1]))) ||
						  ($i==2 && ($x==$x_size-1 || !($wall[$x+1]->[$y]))) ||
						  ($i==3 && ($y==0  || !($wall[$x]->[$y-1]))) 
						 ) {
						glColor3f($r[$i],$g[$i],$b[$i]);
 						glBegin(GL_POLYGON);
						#print " begin poly $x,$y  $i\n";
        					for($j=0;$j<4;$j++){
                					$k=$cf[$i*4+$j];
                					glVertex3d($x+$cx[$k],$y+$cy[$k],$cz[$k]);
					        }
						glEnd();
					}
				}
			}
		}
	}
	glColor3f(0,1,0);
	glBegin(GL_POLYGON);
	glVertex3f(1+0.2,1+0.2,0);
	glVertex3f(1+0.2,1+0.8,0);
	glVertex3f(1+0.8,1+0.8,0);
	glVertex3f(1+0.8,1+0.2,0);
	glEnd();

	glColor3f(1,0,0);
	glBegin(GL_POLYGON);
	glVertex3f($x_size-2+0.2,$y_size-2+0.2,0);
	glVertex3f($x_size-2+0.2,$y_size-2+0.8,0);
	glVertex3f($x_size-2+0.8,$y_size-2+0.8,0);
	glVertex3f($x_size-2+0.8,$y_size-2+0.2,0);
	glEnd();

	glEndList();
	$dl;
}

package A;

use OpenGL;
%defaults = (
        'name' => 'unnamed',
        'x' => 0 ,
        'y' => 0 ,
        'z' => 0 ,
        'dx'=> 0,
        'dy'=> 0,
        'dz'=> 0,
	'angle' => 0,
        'dl'=> $main::shot,
);
sub initialize {
        my $self=shift;
        local %v = @_;
        foreach $k (keys(%v)) {
                $self->{$k} = $v{$k};
        }
        $self;
}

sub print{
        my $self=shift;
        print "\tObject '",$self->{'name'},"' is a '",ref($self),"'\n";
        foreach $k (sort keys(%$self)) {
                print("\t\t$k\t$self->{$k}\n") if($k cmp 'name');
        }
        print "\n";
}

sub new {
        my $type = shift;
        my $self = {};
        initialize($self,%defaults);
        initialize($self,@_);
        push(@objects,$self);
        bless $self;
}
sub move {
	my $self=shift;
	local $h;
	($self->{'x'},$self->{'y'},$h) = &main::forward($self->{'x'},
						$self->{'y'},
						$self->{'x'}+$self->{'dx'},
						$self->{'y'}+$self->{'dy'},0.01);
	#print "bullet $self->{'x'},$self->{'y'} $self->{'dx'},$self->{'dy'} $self \n";
	if($h) { 
		local($i,$k);
		$k=-1;
		for($i=0;$i<=$#objects;$i++) {
			($k=$i) if($objects[$i] == $self) ;
		}
		$k==-1 and die "hey k= $k\n";
		splice(@objects,$k,1);
		$self->{'dl'} = 4;
		#print "dead\n";
	}
}
sub draw {
       my $self=shift;
        glPushMatrix();
        glTranslatef($self->{'x'},$self->{'y'},$self->{'z'});
	glRotatef($self->{'angle'},0,0,1);
        #glCallList($self->{'dl'});
        glCallList($self->{'dl'});
        #glCallList($main::shot);
        glPopMatrix ();
}

package main;

sub check_events {
	while(XPending) {
		my @e=&glpXNextEvent;
		my %s;
		&$s(@e) if($s=$cb{$e[0]});
        }
}

sub intro {
  # give a cool intro to the thing
  # spin the maze around on 2 axis then
  # zoom in to the starting position.
  local($spin,$p);
  $spin=360*2;
  while($spin-=5) {
    check_events;
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    glPushMatrix();
    glTranslatef(0,0,-20);
    glRotatef($spin, 0.0, 1.0, 1.0);
    glTranslatef(-$x_size/2,-$y_size/2,0);
    glCallList($walls);
    glPopMatrix();
    glXSwapBuffers;
  }
  for($p=0 ; $p <= 1 ; $p+=0.02) {
    check_events;
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    glPushMatrix();
    glRotatef(-90*$p,1,0,0);

    glRotatef($b*$p,0,0,1);

    glTranslatef(-$x*$p + -$x_size/2*(1-$p),-$y*$p+ -$y_size/2*(1-$p),-0.5*$p + -20*(1-$p));

    glCallList($walls);
    glPopMatrix();
    glXSwapBuffers;
  }
}

$x=1.5 ; $y=1.5 ; $b = 90 ;

sub forward {
	# this routine does wall collision detection
	# the inputs to this routine are:
	#         - the current location
	#         - the desired location 
	#         - the minimum distance to wall allowed 
	# returns
	#         - new coordinates after move
	#         - whether a wall caused change in target position
	# This is really easy with these walls that lie only on axes.
	local($x,$y,$px,$py, $bf) = @_;
	local($h)=(0);
	if($px>int($x)+1.0-$bf && $wall[$x+1]->[$y]) {
		$px = int($x)+1.0-$bf;
		$h++;
	}
	if($py>int($y)+1.0-$bf && $wall[$x]->[$y+1]) {
		$py = int($y)+1.0-$bf;
		$h++;
	}
	if($px<int($x)+$bf && $wall[$x-1]->[$y]) {
		$px = int($x)+$bf;
		$h++;
	}
	if($py<int($y)+$bf && $wall[$x]->[$y-1]) {
		$py = int($y)+$bf;
		$h++;
	}
	($px,$py,$h);
}
sub abs {
	($_[0] > 0) ? $_[0] : - $_[0];
}

sub nav {
    check_events;

    # routine for navigating through the maze
    $t++;
    ($px,$py,$pm) = glpXQueryPointer;
    $rot = 0;
    if ($pm & Button1Mask) { $rot = -1; }  
    if ($pm & Button3Mask) { $rot = 1; }  
    $rot = 2*$px/$width - 1 if !$rot && ($pm & Button2Mask);
    $b += (( $pm & (ShiftMask)) ?9 :3) * $rot;
    if ($pm & Button2Mask) { 
	$speed = ( $pm & (ShiftMask)) ?0.15 : 0.05;
	($x,$y) = forward($x,$y,$x+$speed*sin($b*3.14/180),
				$y+$speed*cos($b*3.14/180),0.2);
    } 
    if( $pm & (ControlMask)) {
	#print "fire\n";
	local($d);
	$d=$b + abs($t*7%60-30)-15;
	new A(x=>$x,y=>$y,z=>0.5,
		dx => 0.08*sin(($d)*3.14/180),dy=>0.08*cos(($d)*3.14/180) ,
		dl=>3,angle=>-($d)
	     );
    }
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    glPushMatrix();
    glRotatef(-90,1,0,0);
    glRotatef($b,0,0,1);
    glTranslatef(-$x,-$y,-0.5);
    glCallList($walls);
    # make copy of list since it may get modified during list traversal
    @objects = @A::objects;  
    foreach $obj (@objects) {
	$obj->move;
	$obj->draw;
    }
    glPopMatrix();
    glXSwapBuffers;
}

$width = 300;

glpOpenWindow(attributes => [GLX_GREEN_SIZE, 1,GLX_RGBA,GLX_DOUBLEBUFFER],
		mask => StructureNotifyMask|KeyPressMask,
		width=>$width,height=>300);

print <<EOP;

Control: MB1/MB3 - turn left/right, MB2 - go (and turn), Control - shoot a wave

EOP

$cb{&ConfigureNotify} = sub {
 local($e,$w,$h)=@_;
 glViewport(0,0,$w,$h);
 print "new viewport $w,$h\n";
 $width = $w;
};

glNewList($shot=3,GL_COMPILE);
glColor3f(0.5,1.0,0.5);
glBegin(GL_POLYGON);
 glNormal3f( 0.10,   0.0,  0.0);
 glVertex3f( 0.0 ,  0.03, -0.04);
 glVertex3f(  0.0030 , -0.01, -0.04);
 glVertex3f( -0.0030 , -0.01, -0.04);
glEnd();
glEndList();
glNewList($smash=4,GL_COMPILE);
glColor3f(1.0,0.5,0);
glBegin(GL_POLYGON);
 glNormal3f( 0.10,   0.0,  0.0);
 glVertex3f( -0.05 ,  0, -0.02);
 glVertex3f( 0.05 ,  0, -0.02);
 glVertex3f(  0.05 ,0, -0.06);
 glVertex3f( -0.05 ,0, -0.06);
glEnd();
glEndList();

glEnable(GL_DEPTH_TEST);
glClearColor(0,0,0,1);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(60.0, 1.0 , 0.1, 60.0); 
    glMatrixMode(GL_MODELVIEW);
glLoadIdentity ();

$walls=drawwalls;

intro;

while(1){nav;}
