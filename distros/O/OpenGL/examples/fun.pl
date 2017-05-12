#!/usr/local/bin/perl 
#
#       object oriented programming example
#
# Example developed entirely by Stan Melax (stan@arc.ab.ca).
# I wanted to try some object-oriented programming in perl,
# but I wanted to do something more real than just a "foo-bar" example :-)
# 
# I developed the smooth "chaseing" behavior used by the spaceship
# years ago in grad school for a VR assignment.  When Randy Pausch
# (a VR God from U of Virginia) visited the U of Alberta, he was
# impressed and took a copy of the algorithm.  
#

BEGIN{ unshift(@INC,"../blib"); }  # in case OpenGL is built but not installed
BEGIN{ unshift(@INC,"../blib/arch"); } # 5.002 gamma needs this
BEGIN{ unshift(@INC,"../blib/lib"); } # 5.002 gamma needs this
use OpenGL;

sub abs{
	(($_[0]>0)?$_[0]:-$_[0]);
}

$cow=1;
$plane=2;
$floor=3;
$enterprise=4;
sub initlists{
	glNewList($cow,GL_COMPILE);
	    glColor3f(1.0,0.0,0.0);
	    glBegin(GL_POLYGON);
	      glNormal3f(-1.0,   0.0,  0.0);
	      glVertex3f(-1.0 , -1.0, -1.0);
	      glVertex3f(-1.0 ,  1.0, -1.0);
	      glVertex3f(-1.0 ,  1.0,  1.0);
	      glVertex3f(-1.0 , -1.0,  1.0);
	    glEnd();
	    glColor3f(0.0,1.0,0.0);
	    glBegin(GL_POLYGON);
	      glNormal3f( 1.0,   0.0,  0.0);
	      glVertex3f( 1.0 , -1.0, -1.0);
	      glVertex3f( 1.0 ,  1.0, -1.0);
	      glVertex3f( 1.0 ,  1.0,  1.0);
	      glVertex3f( 1.0 , -1.0,  1.0);
	    glEnd();
	glEndList();

	glNewList($plane,GL_COMPILE);
	    glColor3f(0,0,0);
	    glBegin(GL_POLYGON);
	      glVertex3f( 1 ,  2,  1.0);
	      glVertex3f( 2 ,  1,  1.0);
	      glVertex3f( 2 ,  -1,  1.0);
	      glVertex3f( 1 ,  -2,  1.0);
	      glVertex3f( -1 ,  -2,  1.0);
	      glVertex3f( -2 ,  -1, 1.0);
	      glVertex3f( -2 ,  1,  1.0);
	      glVertex3f( -1 ,  2,  1.0);
	    glEnd();
	    glColor3f(1.0,0.0,1.0);
	    glBegin(GL_POLYGON);
	      glVertex3f( 1 ,  2,  3.0);
	      glVertex3f( 2 ,  1,  3.0);
	      glVertex3f( 2 ,  -1,  3.0);
	      glVertex3f( 1 ,  -2,  3.0);
	      glVertex3f( -1 ,  -2,  3.0);
	      glVertex3f( -2 ,  -1,  3.0);
	      glVertex3f( -2 ,  1,  3.0);
	      glVertex3f( -1 ,  2,  3.0);
	    glEnd();
	glEndList();

	glNewList($floor,GL_COMPILE);
	 for($i=0;$i<10;$i++) {
	  for($j=0;$j<10;$j++) {
	    $b = 1-sqrt(($i-4.5)*($i-4.5)+($j-4.5)*($j-4.5))/6.4;
	    glColor3f($b*0.5,(($i%2) ^ ($j%2) )?0.7*$b : 0 ,0);
	    glBegin(GL_POLYGON);
	      glVertex3f( (0+$i-5)*10 ,  (0+$j-5) *10,  0.0);
	      glVertex3f( (1+$i-5)*10 ,  (0+$j-5) *10,  0.0);
	      glVertex3f( (1+$i-5)*10 ,  (1+$j-5) *10,  0.0);
	      glVertex3f( (0+$i-5)*10 ,  (1+$j-5) *10,  0.0);
	    glEnd();
	  }
	 }
	glEndList();
}

sub readnff{
  my $file = 'spaceship.nff';
  $file = "examples/$file" unless -r $file;
  open(FILE,"<$file") || die "cant open $file";
  $_="";
  while(!(/^82\s*$/)){$_=<FILE>;}
  $n=82;
  for($i=0;$i<$n;$i++) {
    $_=<FILE>;
    /(\S+)\s+(\S+)\s+(\S+)\s*$/ || die "couldn't parse file";
    ($x[$i],$y[$i],$z[$i])=($1,$2,$3);
  }
  $_=<FILE>;
  /^140/ || die "couldn't parse file";
  $p=140;
  glNewList($enterprise,GL_COMPILE);
  glScalef(0.02,0.02,0.02);
  glRotatef(90.0,0.0,0.0,1.0);
  glColor3f(0.0,1.0,1.0);
  for($i=0;$i<$p;$i++) {
    glBegin(GL_POLYGON);
    $_=<FILE>;
    /3\s+(\d+)\s+(\d+)\s+(\d+)\s/ || die "couldn't parse file";
    glVertex3f($x[$1],$y[$1],$z[$1]);
    glVertex3f($x[$2],$y[$2],$z[$2]);
    glVertex3f($x[$3],$y[$3],$z[$3]);
    glEnd();
  }
  close(FILE);
  glEndList();
  $enterprise;
}

package A;

use OpenGL;
%defaults = (
	'name' => 'unnamed',
	'x' => 0 ,
	'y' => 0 ,
	'z' => 0 ,
	'dl'=> $main::plane,
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
}
sub draw {
	my $self=shift;
	glPushMatrix();
	glTranslatef($self->{'x'},$self->{'y'},$self->{'z'});
	glCallList($self->{'dl'});
	glPopMatrix ();
}


#------------------------------------------
package B;
@ISA=qw(A);

%defaults = (
	'dx',0,
	'dy',0,
	'dz',0,
);
sub new {
	my $type = shift;
	my $self = new A(%defaults,@_);
	push(@objects,$self);
	bless $self;
}

$WORLD_BOUNDARY =(20.0);
$WORLD_CEILING  =(10.0);
$WORLD_FLOOR    =(0.0);
sub move {
  my $self = shift;
  local($x,$y,$z,$dx,$dy,$dz)=
	(\$self->{'x'}, \$self->{'y'}, \$self->{'z'},
         \$self->{'dx'},\$self->{'dy'},\$self->{'dz'});
  $$x+=$$dx;
  $$y+=$$dy;
  $$z+=$$dz;
  # Bounce off Walls 
  ($$x>  $WORLD_BOUNDARY) && ($$dx= -abs($$dx));
  ($$x< -$WORLD_BOUNDARY) && ($$dx=  abs($$dx));
  ($$y>  $WORLD_BOUNDARY) && ($$dy= -abs($$dy));
  ($$y< -$WORLD_BOUNDARY) && ($$dy=  abs($$dy));
  ($$z>  $WORLD_CEILING ) && ($$dz= -abs($$dz));
  ($$z<  $WORLD_FLOOR   ) && ($$dz=  abs($$dz));
}


#------------------------------------------
package T;
@ISA=qw(B);
%defaults = (
	'name','target',
	'wait',0,
);
$damping = 0.99;
sub new {
	my $type = shift;
	my $self = new B(%defaults,@_);
	push(@objects,$self);
	bless $self;
}
sub move {
	my $self = shift;
	$self->{'dx'} *= $damping;
	$self->{'dy'} *= $damping;
	$self->{'wait'}-- if($self->{'wait'}>0) ;
	$self->B::move;
}
sub takeoff {
	my $self = shift;
	#print "takeoff\n";
	return if($self->{'wait'}>0) ;
	$self->{'dx'} = rand(2)-1.0;
	$self->{'dy'} = rand(2)-1.0;
	$self->{'wait'}=10;
}
#------------------------------------------
package C;
@ISA=qw(B);
use OpenGL;

%defaults = (
	'target' => 0,
	'h' => 0,
	'dh' => 0,
);
sub new {
	my $type = shift;
	my $self = new B(%defaults,@_);
	push(@objects,$self);
	bless $self;
}
$DAMPING 	= (0.98);
$ACCELLERATION 	= (0.01);
$BANK_DAMPING 	= (0.8);
sub move{
  	my $self = shift;
  	local($x,$y,$z,$dx,$dy,$dz,$h,$dh)=
		(\$self->{'x'}, \$self->{'y'}, \$self->{'z'},
        	 \$self->{'dx'},\$self->{'dy'},\$self->{'dz'},
		 \$self->{'h'},\$self->{'dh'});
	local $t  = $self->{'target'};
	($t) || die "No Target\n"; 
	local ($tx,$ty) = ($t->{'x'},$t->{'y'});
	
   	local $theading = atan2($ty-$$y,$tx-$$x);
	local $speed = sqrt($$dx*$$dx+$$dy*$$dy);
	$$h = ($$dy==0.0&&$$dx==0.0)? $$h : atan2($$dy,$$dx);
	$tdheading = $theading-$$h;
	while($tdheading > 3.14){ $tdheading -= 2*3.14};
	while($tdheading <-3.14){ $tdheading += 2*3.14};
	$$dh*= $BANK_DAMPING; 
	$$dh += $tdheading* 0.01;
	$$h += $$dh;
	if($tdheading <3.14/6 && $tdheading>-3.14/6 ) {
		$speed += $ACCELLERATION;
	}
    	elsif ($tdheading <3.14/3 && $tdheading>-3.14/3 ) {
		$speed += $ACCELLERATION/4;
	}
	$$dx = cos($$h)*$speed;
	$$dy = sin($$h)*$speed;
	#if( (t%10==0) && tdheading <3.14/6 && tdheading>-3.14/6 ){
	#	# fire();
	#}
	# damping 
	$$dx *= $DAMPING;
	$$dy *= $DAMPING;
	$$dz *= $DAMPING;
	#$self->B::move;
  	$$x+=$$dx;
  	$$y+=$$dy;
  	$$z+=$$dz;
	$t->takeoff if($$x > $tx-5 && $$x < $tx+5  &&
	   $$y > $ty-5 && $$y < $ty+5 );
}

sub draw {
	my $self=shift;
	glPushMatrix();
	glTranslatef($self->{'x'},$self->{'y'},$self->{'z'});
	glRotatef($self->{'h'}*180/3.14, 0.0,0.0,1.0);
	glRotatef(-60.0 * $self->{'dh'}/(1.0/(1.0-0.8)*0.01*3.14), 1.0, 0.0, 0.0);
	glCallList($self->{'dl'});
	glPopMatrix ();
}

#------------------------------------------
package main;

glpOpenWindow(width=>400,height=>400,
	      mask => StructureNotifyMask|KeyPressMask,
	      attributes=>[GLX_RGBA,GLX_DOUBLEBUFFER]);
glShadeModel (GL_FLAT);

glMatrixMode(GL_PROJECTION);
glLoadIdentity();
glFrustum (-1.0, 1.0, -1.0, 1.0, 1.5, 500.0); 
glMatrixMode(GL_MODELVIEW);


initlists;
glColor3f(1,0,0);
glClearColor(0,0,0.3,1);

new A('dl'=>$floor,'name'=>'the happy floor');
#$a = new A( 'y' => 0.2,  'name' => 'useless dude');
$b = new T( 'x' => 10, 'dx'=> 0.4,  'name' => 'bad dude');
readnff;
$c = new C('z' => 5,'dl'=>$enterprise, 'x' => -10, 'target'=>$b, 'name' => 'killer');
$w=100.0;$t= time;$p= $t-1;
$rin=$win=$ein='';
$spf = 1;
$spin=0;

$cb{&ConfigureNotify} = sub { local($e,$w,$h)=@_;glViewport(0,0,$w,$h);
                         # print "viewport $w,$h\n";
                        };
$cb{&KeyPress} = sub { # print "@_[1] ",ord(@_[1])," keypress @_\n";
                      local($ss); &$ss(@_[1]) if ($ss=$kcb{@_[1]}); };
$kcb{'q'} = $kcb{'Q'} = $kcb{"\033"} = sub{ print "Good-Bye\n"; exit 0;};
sub setspeed{$C::ACCELLERATION =  $_[0]/100;}
foreach $i (0..9){
        $kcb{"$i"}=\&setspeed;
}

$is_pm = OpenGL::_have_glp && ! OpenGL::_have_glx;

while(1){
	$spf = ($spf*$w + $t-$p) /($w+1.0); 
	$fps = ($spf)?1.0/$spf:0;
	$p=$t;
	$t= time;

	while($p=XPending) {
		@e=&glpXNextEvent;
		&$s(@e) if($s=$cb{$e[0]});
        }


	vec($rin,0,1) = 1;
	if(!$is_pm && select($rout=$rin,undef,undef,0)) {
		$_=<> || die "End Of File";
		eval;
	}
	foreach $x (@A::objects) {
		$x->move;
		#$x->print;
	}
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
	glLoadIdentity ();

	# set the viewpoint
	glTranslatef (0.0, 0.0, -30.0);    
	glRotatef(-45.0, 1.0,0.0,0.0);
	$spin += 1;
	glRotatef($spin, 0.0,0.0,1.0);
	
	foreach $x (@A::objects) {
		$x->draw;
	}
	glFlush();
	glXSwapBuffers;
}

__END__
