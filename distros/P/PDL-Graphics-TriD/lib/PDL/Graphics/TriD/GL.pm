use strict;
use warnings;
no warnings 'redefine';
use OpenGL qw/ :glfunctions :glconstants gluPerspective gluOrtho2D /;
use PDL::Core qw(barf);

sub PDL::Graphics::TriD::Material::togl{
  my $this = shift;
  my $shin = pack "f*",$this->{Shine};
  glMaterialfv(GL_FRONT_AND_BACK,GL_SHININESS,$shin);
  my $spec = pack "f*",@{$this->{Specular}};
  glMaterialfv(GL_FRONT_AND_BACK,GL_SPECULAR,$spec);
  my $amb = pack "f*",@{$this->{Ambient}};
  glMaterialfv(GL_FRONT_AND_BACK,GL_AMBIENT,$amb);
  my $diff = pack "f*",@{$this->{Diffuse}};
  glMaterialfv(GL_FRONT_AND_BACK,GL_DIFFUSE,$diff);
}

$PDL::Graphics::TriD::verbose //= 0;

sub PDL::Graphics::TriD::Object::gl_update_list {
  my($this) = @_;
  glDeleteLists($this->{List},1) if $this->{List};
  $this->{List} = my $lno = glGenLists(1);
  print "GENLIST $lno\n" if($PDL::Graphics::TriD::verbose);
  glNewList($lno,GL_COMPILE);
  eval {
    my @objs = @{$this->{Objects}};
    $_->togl() for @objs;
    print "EGENLIST $lno\n" if($PDL::Graphics::TriD::verbose);
  };
  { local $@; glEndList(); }
  die if $@;
  print "VALID1 $this\n" if($PDL::Graphics::TriD::verbose);
  $this->{ValidList} = 1;
}

sub PDL::Graphics::TriD::Object::gl_call_list {
	my($this) = @_;
	print "CALLIST ",$this->{List}//'undef',"!\n" if $PDL::Graphics::TriD::verbose;
	print "CHECKVALID $this=$this->{ValidList}\n" if $PDL::Graphics::TriD::verbose;
	$this->gl_update_list if !$this->{ValidList};
	glCallList($this->{List});
}

sub PDL::Graphics::TriD::Object::delete_displist {
	my($this) = @_;
	return if !$this->{List};
	glDeleteLists($this->{List},1);
	delete @$this{qw(List ValidList)};
}

sub PDL::Graphics::TriD::Object::togl { $_->togl for @{$_[0]->{Objects}} }

my @bb1 = ([0,4,2],[0,1,2],[0,1,5],[0,4,5],[0,4,2],[3,4,2],
	   [3,1,2],[3,1,5],[3,4,5],[3,4,2]);
my @bb2 = ([0,1,2],[3,1,2],[0,1,5],[3,1,5],[0,4,5],[3,4,5]);
sub PDL::Graphics::TriD::BoundingBox::togl {
  my($this) = @_;
  $this = $this->{Box};
  glDisable(GL_LIGHTING);
  glColor3d(1,1,1);
  glBegin(GL_LINES);
  glVertex3d(@{$this}[@$_]) for @bb1;
  glEnd();
  glBegin(GL_LINE_STRIP);
  glVertex3d(@{$this}[@$_]) for @bb2;
  glEnd();
  glEnable(GL_LIGHTING);
}

sub PDL::Graphics::TriD::Graph::togl {
	my($this) = @_;
	$this->{Axis}{$_}->togl_axis($this) for grep $_ ne "Default", keys %{$this->{Axis}};
	$this->{Data}{$_}->togl_graph($this,$this->get_points($_)) for keys %{$this->{Data}};
}

use PDL;
sub PDL::Graphics::TriD::CylindricalEquidistantAxes::togl_axis {
	my($this,$graph) = @_;
        my (@nadd,@nc,@ns);
	for my $dim (0..1) {
	  my $width = $this->{Scale}[$dim][1]-$this->{Scale}[$dim][0];
	  if($width > 100){
	    $nadd[$dim] = 10;
	  }elsif($width>30){
	    $nadd[$dim] = 5;
	  }elsif($width>20){
	    $nadd[$dim] = 2;
	  }else{
	    $nadd[$dim] = 1;
	  }
	  $nc[$dim] = int($this->{Scale}[$dim][0]/$nadd[$dim])*$nadd[$dim];
	  $ns[$dim] = int($width/$nadd[$dim])+1;
	}
	# can be changed to topo heights?
	my $verts = zeroes(3,$ns[0],$ns[1]);
	(my $t = $verts->slice("2")) .= 1012.5;
	($t = $verts->slice("0")) .= $verts->ylinvals($nc[0],$nc[0]+$nadd[0]*($ns[0]-1));
	($t = $verts->slice("1")) .= $verts->zlinvals($nc[1],$nc[1]+$nadd[1]*($ns[1]-1));
	my $tverts = zeroes(3,$ns[0],$ns[1]);
	$tverts = $this->transform($tverts,$verts,[0,1,2]);
	glDisable(GL_LIGHTING);
	glColor3d(1,1,1);
	for(my $j=0;$j<$tverts->getdim(2)-1;$j++){
	  my $j1=$j+1;
	  glBegin(GL_LINES);
	  for(my $i=0;$i<$tverts->getdim(1)-1;$i++){
	    my $i1=$i+1;
	    glVertex2f($tverts->at(0,$i,$j),$tverts->at(1,$i,$j));
	    glVertex2f($tverts->at(0,$i1,$j),$tverts->at(1,$i1,$j));
	    glVertex2f($tverts->at(0,$i1,$j),$tverts->at(1,$i1,$j));
	    glVertex2f($tverts->at(0,$i1,$j1),$tverts->at(1,$i1,$j1));
	    glVertex2f($tverts->at(0,$i1,$j1),$tverts->at(1,$i1,$j1));
	    glVertex2f($tverts->at(0,$i,$j1),$tverts->at(1,$i,$j1));
	    glVertex2f($tverts->at(0,$i,$j1),$tverts->at(1,$i,$j1));
	    glVertex2f($tverts->at(0,$i,$j),$tverts->at(1,$i,$j));
	  }
	  glEnd();
	}
	glEnable(GL_LIGHTING);
}

sub PDL::Graphics::TriD::EuclidAxes::togl_axis {
	my($this,$graph) = @_;
        print "togl_axis: got object type " . ref($this) . "\n" if $PDL::Graphics::TriD::verbose;
	glLineWidth(1); # ought to be user defined
	glDisable(GL_LIGHTING);
	my $ndiv = 4;
	my $line_coord = zeroes(3,3)->append(my $id3 = identity(3));
	my $starts = zeroes($ndiv+1)->xlinvals(0,1)->transpose->append(zeroes(2,$ndiv+1));
	my $ends = $starts + append(0, ones 2) * -0.1;
	my $dupseq = sequence(3)->dummy(0,$ndiv+1)->flat;
	$_ = $_->dup(1,3)->rotate($dupseq) for $starts, $ends;
	$line_coord = $line_coord->glue(1, $starts->append($ends));
	my $axisvals = zeroes(3,$ndiv+1)->ylinvals($this->{Scale}->dog)->transpose->flat->transpose;
	my @label = map sprintf("%.3f", $_), @{ $axisvals->flat->unpdl };
	push @label, @{$this->{Names}};
	glColor3d(1,1,1);
	PDL::Graphics::OpenGLQ::gl_texts($ends->glue(1, $id3), \@label);
	PDL::gl_lines_nc($line_coord->splitdim(0,3)->clump(1,2));
	glEnable(GL_LIGHTING);
}

use POSIX qw//;
sub PDL::Graphics::TriD::Quaternion::togl {
  my($this) = @_;
  if(abs($this->[0]) == 1) { return ; }
  if(abs($this->[0]) >= 1) {
    $this->normalise;
  }
  glRotatef(2*POSIX::acos($this->[0])/3.14*180, @{$this}[1..3]);
}

##################################
# Graph Objects

sub PDL::Graphics::TriD::GObject::togl {
	$_[0]->gdraw($_[0]->{Points});
}

# (this,graphs,points)
sub PDL::Graphics::TriD::GObject::togl_graph {
	$_[0]->gdraw($_[2]);
}

sub PDL::Graphics::TriD::Points::gdraw {
	my($this,$points) = @_;
	glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT);
	$this->glOptions;
	glDisable(GL_LIGHTING);
	eval {
	  PDL::gl_points_col($points,$this->{Colors});
	};
	{ local $@; glPopAttrib(); }
	die if $@;
}

sub PDL::Graphics::TriD::Spheres::gdraw {
   my($this,$points) = @_;
   glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT);
   $this->glOptions;
   glEnable(GL_LIGHTING);
   glShadeModel(GL_SMOOTH);
   eval {
      PDL::gl_spheres($points, 0.025, 15, 15);
   };
   { local $@; glPopAttrib(); }
   die if $@;
}

sub PDL::Graphics::TriD::Lattice::gdraw {
	my($this,$points) = @_;
	barf "Need 3D points AND colours"
	  if grep $_->ndims < 3, $points, $this->{Colors};
	glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT);
	$this->glOptions;
	glDisable(GL_LIGHTING);
	eval {
	  PDL::gl_line_strip_col($points,$this->{Colors});
	  PDL::gl_line_strip_col($points->xchg(1,2),$this->{Colors}->xchg(1,2));
	};
	{ local $@; glPopAttrib(); }
	die if $@;
}

sub PDL::Graphics::TriD::LineStrip::gdraw {
	my($this,$points) = @_;
	glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT);
	$this->glOptions;
	glDisable(GL_LIGHTING);
	eval {
	  PDL::gl_line_strip_col($points,$this->{Colors});
	};
	{ local $@; glPopAttrib(); }
	die if $@;
}

sub PDL::Graphics::TriD::Lines::gdraw {
	my($this,$points) = @_;
	glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT);
	$this->glOptions;
	glDisable(GL_LIGHTING);
	eval {
	  PDL::gl_lines_col($points,$this->{Colors});
	};
	{ local $@; glPopAttrib(); }
	die if $@;
}

sub PDL::Graphics::TriD::GObject::glOptions {
  my ($this) = @_;
  glLineWidth($this->{Options}{LineWidth} || 1);
  glPointSize($this->{Options}{PointSize} || 1);
  glEnable(GL_DEPTH_TEST); # moved here from gdriver else GLFW evaporates it
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, GL_TRUE);
  glLightfv_s(GL_LIGHT0,GL_POSITION,pack "f*",1.0,1.0,1.0,0.0);
}

sub PDL::Graphics::TriD::GObject::_lattice_lines {
  my ($this, $points) = @_;
  glDisable(GL_LIGHTING);
  glColor3f(0,0,0);
  PDL::gl_line_strip_nc($points);
  PDL::gl_line_strip_nc($points->xchg(1,2));
}

sub PDL::Graphics::TriD::Contours::gdraw {
  my ($this,$points) = @_;
  glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT);
  $this->glOptions;
  glDisable(GL_LIGHTING);
  eval {
    my $pi = $this->{PathIndex};
    my ($pcnt, $i, $thisind) = (0, 0, 0);
    for my $ie (grep defined, @{$this->{ContourPathIndexEnd}}) {
      my $colors = $this->{Colors};
      $colors = $colors->slice(":,($i)") if $colors->getndims==2;
      my $this_pi = $pi->slice("$pcnt:$ie");
      for ($this_pi->list) {
        PDL::gl_line_strip_col($points->slice(",$thisind:$_"), $colors);
        $thisind = $_ + 1;
      }
      $i++;
      $pcnt=$ie+1;
    }
    if (defined $this->{Labels}){
	   glColor3d(1,1,1);
	   my $seg = sprintf ":,%d:%d",$this->{Labels}[0],$this->{Labels}[1];
	   PDL::Graphics::OpenGLQ::gl_texts($points->slice($seg),
		   $this->{LabelStrings});
    }
  };
  { local $@; glPopAttrib(); }
  die if $@;
}

my @sls1 = (
  ":,0:-2,0:-2",
  ":,1:-1,0:-2",
  ":,0:-2,1:-1");
my @sls2 = (
  ":,1:-1,1:-1",
  ":,0:-2,1:-1",
  ":,1:-1,0:-2");
sub _lattice_slice {
  my ($f, @pdls) = @_;
  for my $s (\@sls1, \@sls2) {
    my @args;
    for my $p (@pdls) {
      push @args, map $p->slice($_), @$s;
    }
    &$f(@args);
  }
}

sub PDL::Graphics::TriD::SLattice::gdraw {
	my($this,$points) = @_;
	barf "Need 3D points"
	  if grep $_->ndims < 3, $points;
	glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT);
	$this->glOptions;
	glDisable(GL_LIGHTING);
	glShadeModel(GL_SMOOTH); # By-vertex doesn't make sense otherwise.
	eval {
	  _lattice_slice(\&PDL::gl_triangles, $points, $this->{Colors});
	  $this->_lattice_lines($points) if $this->{Options}{Lines};
	};
	{ local $@; glPopAttrib(); }
	die if $@;
}

sub PDL::Graphics::TriD::SCLattice::gdraw {
	my($this,$points) = @_;
	barf "Need 3D points"
	  if grep $_->ndims < 3, $points;
	glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT);
	$this->glOptions;
	glDisable(GL_LIGHTING);
	glShadeModel(GL_FLAT); # By-vertex doesn't make sense otherwise.
	eval {
	  _lattice_slice(\&PDL::gl_triangles, $points, $this->{Colors});
	  $this->_lattice_lines($points) if $this->{Options}{Lines};
	};
	{ local $@; glPopAttrib(); }
	die if $@;
}

sub PDL::Graphics::TriD::SLattice_S::gdraw {
  my($this,$points) = @_;
  barf "Need 3D points"
    if grep $_->ndims < 3, $points;
  glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT);
  $this->glOptions;
  glShadeModel(GL_SMOOTH); # By-vertex doesn't make sense otherwise.
  eval {
    my $f = 'PDL::gl_triangles_';
    $f .= 'w' if $this->{Options}{Smooth};
    $f .= 'n_mat';
    { no strict 'refs'; $f = \&$f; }
    my @pdls = $points;
    push @pdls, $this->{Normals} if $this->{Options}{Smooth};
    push @pdls, $this->{Colors};
    _lattice_slice($f, @pdls);
    $this->_lattice_lines($points) if $this->{Options}{Lines};
    if ($this->{Options}{ShowNormals}) {
      die "No normals to show!" if !defined $this->{Normals};
      my $arrows = $points->append($points + $this->{Normals}*0.1)->splitdim(0,3);
      glDisable(GL_LIGHTING);
      glColor3d(1,1,1);
      PDL::Graphics::OpenGLQ::gl_arrows($arrows, 0, 1, 0.5, 0.02);
    }
  };
  { local $@; glPopAttrib(); }
  die if $@;
}

sub PDL::Graphics::TriD::STrigrid_S::gdraw {
  my($this,$points) = @_;
  my $faces = $points->dice_axis(1,$this->{Faceidx}->flat)->splitdim(1,3);
  glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT);
  $this->glOptions;
  eval {
    glShadeModel(GL_SMOOTH); # By-vertex doesn't make sense otherwise.
    my @sls = (":,(0)",":,(1)",":,(2)");
    my $idx = [0,1,2,0]; # for lines, below
    if ($this->{Options}{Smooth}) {
      my $tmpn=$this->{Normals}->dice_axis(1,$this->{Faceidx}->flat)
		      ->splitdim(1,$this->{Faceidx}->dim(0));
      PDL::gl_triangles_wn_mat(map $_->mv(1,-1)->dog, $faces, $tmpn, $this->{Colors});
      if ($this->{Options}{ShowNormals}) {
	my $arrows = $points->append($points + $this->{Normals}*0.1)->splitdim(0,3);
	glDisable(GL_LIGHTING);
	glColor3d(1,1,1);
	PDL::Graphics::OpenGLQ::gl_arrows($arrows, 0, 1, 0.5, 0.02);
	my $facecentres = $faces->transpose->avgover;
	my $facearrows = $facecentres->append($facecentres + $this->{FaceNormals}*0.1)->splitdim(0,3);
	glColor3d(0.5,0.5,0.5);
	PDL::Graphics::OpenGLQ::gl_arrows($facearrows, 0, 1, 0.5, 0.02);
      }
    } else {
      PDL::gl_triangles_n_mat(map $_->mv(1,-1)->dog, $faces, $this->{Colors});
    }
    if ($this->{Options}{Lines}) {
      glDisable(GL_LIGHTING);
      glColor3f(0,0,0);
      PDL::gl_lines_nc($this->{Faces}->dice_axis(1,$idx));
    }
  };
  { local $@; glPopAttrib(); }
  die if $@;
}

sub PDL::Graphics::TriD::STrigrid::gdraw {
  my($this,$points) = @_;
  my $faces = $points->dice_axis(1,$this->{Faceidx}->flat)->splitdim(1,3);
  # faces is 3D pdl slices of points, giving cart coords of face verts
  glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT);
  $this->glOptions;
  eval {
    glDisable(GL_LIGHTING);
    glShadeModel(GL_SMOOTH); # By-vertex doesn't make sense otherwise.
    PDL::gl_triangles(map $_->mv(1,-1)->dog, $faces, $this->{Colors});
    if ($this->{Options}{Lines}) {
      glColor3f(0,0,0);
      PDL::gl_lines_nc($faces->dice_axis(1, [0,1,2,0]));
    }
  };
  { local $@; glPopAttrib(); }
  die if $@;
}

##################################
# PDL::Graphics::TriD::Image

sub PDL::Graphics::TriD::Image::togl {
# A special construct which always faces the display and takes the entire window
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluOrtho2D(0,1,0,1);
  &PDL::Graphics::TriD::Image::togl_graph;
}

sub PDL::Graphics::TriD::Image::togl_graph {
	$_[0]->gdraw();
}

# The quick method is to use texturing for the good effect.
sub PDL::Graphics::TriD::Image::gdraw {
	my($this,$vert) = @_;
	my ($p,$xd,$yd,$txd,$tyd) = $this->flatten(1); # do binary alignment
	if(!defined $vert) {$vert = $this->{Points}}
	barf "Need 3,4 vert"
	  if grep $_->dim(1) < 4 || $_->dim(0) != 3, $vert;
	glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT);
	glColor3d(1,1,1);
         glTexImage2D_s(GL_TEXTURE_2D, 0, GL_RGB, $txd, $tyd, 0, GL_RGB, GL_FLOAT, $p->get_dataref());
	 glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
	       glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
	          glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
	glDisable(GL_LIGHTING);
	glNormal3d(0,0,1);
	glEnable(GL_TEXTURE_2D);
	glBegin(GL_QUADS);
	eval {
	  my @texvert = (
		  [0,0],
		  [$xd/$txd, 0],
		  [$xd/$txd, $yd/$tyd],
		  [0, $yd/$tyd]
	  );
	  for(0..3) {
		  glTexCoord2f(@{$texvert[$_]});
		  glVertex3f($vert->slice(":,($_)")->list);
	  }
	};
	{ local $@; glEnd(); glPopAttrib(); }
	die if $@;
}

sub PDL::Graphics::TriD::SimpleController::togl {
	my($this) = @_;
	$this->{CRotation}->togl();
	glTranslatef(0,0,-$this->{CDistance});
	$this->{WRotation}->togl();
	glTranslatef(map {-$_} @{$this->{WOrigin}});
}

##############################################
# A window with mouse control over rotation.
package PDL::Graphics::TriD::Window;

use OpenGL qw/ :glfunctions :glconstants /;

use base qw/PDL::Graphics::TriD::Object/;
use fields qw/Ev Width Height Interactive _GLObject
              _ViewPorts _CurrentViewPort /;

sub gdriver {
  my($this, $options) = @_;
  print "GL gdriver...\n" if($PDL::Graphics::TriD::verbose);
  if(defined $this->{_GLObject}){
    print "WARNING: Graphics Driver already defined for this window \n";
    return;
  }
  my $window_type = $ENV{POGL_WINDOW_TYPE} || 'glfw';
  my $gl_class = $window_type =~ /x11/i ? 'PDL::Graphics::TriD::GL::GLX' :
    $window_type =~ /glut/i ? 'PDL::Graphics::TriD::GL::GLUT' :
    'PDL::Graphics::TriD::GL::GLFW';
  (my $file = $gl_class) =~ s#::#/#g; require "$file.pm";
  print "gdriver: Calling $gl_class(@$options{qw(width height)})\n" if $PDL::Graphics::TriD::verbose;
  $this->{_GLObject} = $gl_class->new($options, $this);
  print "gdriver: Calling glClearColor...\n" if $PDL::Graphics::TriD::verbose;
  glClearColor(0,0,0,1);
  glShadeModel(GL_FLAT);
  glEnable(GL_NORMALIZE);
  glColor3f(1,1,1);
  print "STARTED OPENGL!\n" if $PDL::Graphics::TriD::verbose;
  if($PDL::Graphics::TriD::offline) {
    $this->doconfig($options->{width}, $options->{height});
  }
  return 1;  # Interactive Window
}

sub ev_defaults{
  return {	ConfigureNotify => \&doconfig,
				MotionNotify => \&domotion,
			}
}

sub reshape {
	my($this,$x,$y) = @_;
	my $pw = $this->{Width};
	my $ph = $this->{Height};
	$this->{Width} = $x; $this->{Height} = $y;
	for my $vp (@{$this->{_ViewPorts}}){
	  my $nw = $vp->{W} + ($x-$pw) * $vp->{W}/$pw;
	  my $nx0 = $vp->{X0} + ($x-$pw) * $vp->{X0}/$pw;
	  my $nh = $vp->{H} + ($y-$ph) * $vp->{H}/$ph;
	  my $ny0 = $vp->{Y0} + ($y-$ph) * $vp->{Y0}/$ph;
	  print "reshape: resizing viewport to $nx0,$ny0,$nw,$nh\n" if($PDL::Graphics::TriD::verbose);
	  $vp->resize($nx0,$ny0,$nw,$nh);
	}
}

sub twiddle {
  my($this,$getout,$dontshow) = @_;
  my (@e);
  my $quit;
  if ($PDL::Graphics::TriD::offline) {
    $PDL::Graphics::TriD::offlineindex ++;
    $this->display();
    require PDL::IO::Pic;
    wpic($this->read_picture(),"PDL_$PDL::Graphics::TriD::offlineindex.jpg");
    return;
  }
  return if $getout and $dontshow and !$this->{_GLObject}->event_pending;
  $getout //= !($PDL::Graphics::TriD::keeptwiddling && $PDL::Graphics::TriD::keeptwiddling);
  $this->display();
  TWIDLOOP: while(1) {
    print "EVENT!\n" if $PDL::Graphics::TriD::verbose;
    my $hap = 0;
    my $gotev = 0;
    if ($this->{_GLObject}->event_pending or !$getout) {
      @e = $this->{_GLObject}->next_event;
      $gotev=1;
    }
    print "e= ".join(",",$e[0]//'undef',@e[1..$#e])."\n" if $PDL::Graphics::TriD::verbose;
    if (@e and defined $e[0]) {
      if ($e[0] eq 'visible') {
        $hap = 1;
      } elsif ($e[0] eq 'reshape') {
        print "CONFIGNOTIFE\n" if $PDL::Graphics::TriD::verbose;
        $this->reshape(@e[1,2]);
        $hap=1;
      } elsif ($e[0] eq 'destroy') {
        print "DESTROYNOTIFE\n" if $PDL::Graphics::TriD::verbose;
        $quit = 1;
        $hap=1;
        $this->close;
        last TWIDLOOP;
      } elsif ($e[0] eq 'keypress') {
        print "KEYPRESS: '$e[1]'\n" if $PDL::Graphics::TriD::verbose;
        if (lc($e[1]) eq "q") {
          $quit = 1;
          last TWIDLOOP if not $getout;
        }
        if (lc($e[1]) eq "c") {
          $quit = 2;
        }
        $hap=1;
      }
    }
    if ($gotev) {
      foreach my $vp (@{$this->{_ViewPorts}}) {
        if (defined($vp->{EHandler})) {
          $hap += $vp->{EHandler}->event(@e) || 0;
        }
      }
    }
    if (!$this->{_GLObject}->event_pending) {
           $this->display if $hap;
           last TWIDLOOP if $getout;
    }
    @e = ();
  }
  print "STOPTWIDDLE\n" if $PDL::Graphics::TriD::verbose;
  return $quit;
}

sub close {
  my ($this, $close_window) = @_;
  print "CLOSE\n" if $PDL::Graphics::TriD::verbose;
  undef $this->{_GLObject};
  $PDL::Graphics::TriD::current_window = undef;
}

# Resize window.
sub doconfig {
	my($this,$x,$y) = @_;
	$this->reshape($x,$y);
	print "CONFIGURENOTIFY\n" if($PDL::Graphics::TriD::verbose);
}

sub domotion {
	my($this) = @_;
	print "MOTIONENOTIFY\n" if($PDL::Graphics::TriD::verbose);
}

sub display {
  my($this) = @_;
  return unless defined($this);
  $this->{_GLObject}->set_window; # for multiwindow support
  print "display: calling glClear()\n" if ($PDL::Graphics::TriD::verbose);
  glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
  glMatrixMode(GL_MODELVIEW);
  for my $vp (@{$this->{_ViewPorts}}) {
	 glPushMatrix();
	 $vp->do_perspective();
	 if($vp->{Transformer}) {
		print "display: transforming viewport!\n" if ($PDL::Graphics::TriD::verbose);
		$vp->{Transformer}->togl();
	 }
	 $vp->gl_call_list();
	 glPopMatrix();
  }
  $this->{_GLObject}->swap_buffers;
  print "display: after SwapBuffers\n" if $PDL::Graphics::TriD::verbose;
}

# should this really be in viewport?
sub read_picture {
	my($this) = @_;
	my($w,$h) = @{$this}{qw/Width Height/};
	my $res = PDL->zeroes(PDL::byte,3,$w,$h);
	glPixelStorei(GL_UNPACK_ALIGNMENT,1);
	glPixelStorei(GL_PACK_ALIGNMENT,1);
        glReadPixels_s(0,0,$w,$h,GL_RGB,GL_UNSIGNED_BYTE,$res->get_dataref);
	return $res;
}

######################################################################
######################################################################
# EVENT HANDLER MINIPACKAGE FOLLOWS!

package PDL::Graphics::TriD::EventHandler;

use OpenGL qw(
  ConfigureNotify MotionNotify DestroyNotify
  ButtonPress ButtonRelease Button1Mask Button2Mask Button3Mask Button4Mask
);

use fields qw/X Y Buttons VP/;
sub new {
  my $class = shift;
  my $vp = shift;
  my $self = fields::new($class);
  $self->{X} = -1;
  $self->{Y} = -1;
  $self->{Buttons} = [];
  $self->{VP} = $vp;
  $self;
}

sub event {
  my($this,$type,@args) = @_;
  print "EH: ",ref($this)," $type (",join(",",@args),")\n" if $PDL::Graphics::TriD::verbose;
  return if !defined $type;
  my $retval;
  if ($type eq 'motion') {
    return if (my $but = $args[0]) < 0;
    print "MOTION $args[0]\n" if $PDL::Graphics::TriD::verbose;
    if ($this->{Buttons}[$but] and $this->{VP}->{Active}) {
      print "calling ".($this->{Buttons}[$but])."->mouse_moved ($this->{X},$this->{Y},$args[1],$args[2])...\n" if $PDL::Graphics::TriD::verbose;
      $retval = $this->{Buttons}[$but]->mouse_moved(@$this{qw(X Y)}, @args[1,2]);
    }
    @$this{qw(X Y)} = @args[1,2];
  } elsif ($type eq 'buttonpress') {
    my $but = $args[0]-1;
    print "BUTTONPRESS $but\n" if $PDL::Graphics::TriD::verbose;
    @$this{qw(X Y)} = @args[1,2];
    $retval = $this->{Buttons}[$but]->ButtonPress(@args[1,2])
      if $this->{Buttons}[$but];
  } elsif ($type eq 'buttonrelease') {
    my $but = $args[0]-1;
    print "BUTTONRELEASE $but\n" if $PDL::Graphics::TriD::verbose;
    $retval = $this->{Buttons}[$but]->ButtonRelease($args[1],$args[2])
      if $this->{Buttons}[$but];
  } elsif ($type eq 'reshape') {
    # Kludge to force reshape of the viewport associated with the window -CD
    print "ConfigureNotify (".join(",",@args).")\n" if $PDL::Graphics::TriD::verbose;
    print "viewport is $this->{VP}\n" if $PDL::Graphics::TriD::verbose;
  }
  $retval;
}

sub set_button {
  my($this,$butno,$act) = @_;
  $this->{Buttons}[$butno] = $act;
}

######################################################################
######################################################################
# VIEWPORT MINI_PACKAGE FOLLOWS!

package PDL::Graphics::TriD::ViewPort;

use OpenGL qw/ :glfunctions :glconstants :glufunctions /;
use PDL::Graphics::OpenGLQ;

sub highlight {
  my ($vp) = @_;
  my $pts = PDL->new([[0,0,0],
		      [$vp->{W},0,0],
		      [$vp->{W},$vp->{H},0],
		      [0,$vp->{H},0],
		      [0,0,0]]);
  glDisable(GL_LIGHTING);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluOrtho2D(0,$vp->{W},0,$vp->{H});
  glLineWidth(4);
  glColor3f(1,1,1);
  gl_line_strip_nc($pts);
  glLineWidth(1);
  glEnable(GL_LIGHTING);
}

sub do_perspective {
  my($this) = @_;
  print "do_perspective ",$this->{W}," ",$this->{H} ,"\n" if $PDL::Graphics::TriD::verbose;
  print Carp::longmess() if $PDL::Graphics::TriD::verbose>1;
  unless($this->{W}>0 and $this->{H}>0) {return;}
  $this->{AspectRatio} = (1.0*$this->{W})/$this->{H};
  glViewport($this->{X0},$this->{Y0},$this->{W},$this->{H});
  $this->highlight if $this->{Active};
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluPerspective(40.0, $this->{AspectRatio} , 0.1, 200000.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity ();
}

package PDL::Graphics::TriD::GL;

use OpenGL ();

use strict;
use warnings;
use PDL::Graphics::TriD::Window qw();
use PDL::Options;

$PDL::Graphics::TriD::verbose //= 0;

# This is a list of all the fields of the opengl object
#use fields qw/Display Window Context Options GL_Vendor GL_Version GL_Renderer/;

=head1 NAME

PDL::Graphics::TriD::GL - PDL TriD OpenGL interface using POGL

=head1 DESCRIPTION

This module provides the glue between the Perl
OpenGL functions and the API defined by the internal
PDL::Graphics::OpenGL one. It also supports any
miscellaneous OpenGL or GUI related functionality to
support PDL::Graphics::TriD refactoring.

It defines an interface that subclasses will conform to, implementing
support for GLFW, GLUT, X11+GLX, etc, as the mechanism for creating windows
and graphics contexts.

=head1 CONFIG

Defaults to using L<OpenGL::GLFW> - override by setting the environment
variable C<POGL_WINDOW_TYPE> to C<glut>, C<x11> , or the default is C<glfw>.
This is implemented by C<PDL::Graphics::TriD::Window::gdriver>.

=head2 new

=for ref

Returns a new OpenGL object.

=for usage

  new($class,$options,[$window_type])

  Attributes are specified in the $options field; the 3d $window_type is optionsl. The attributes are:

=over

=item x,y - the position of the upper left corner of the window (0,0)

=item width,height - the width and height of the window in pixels (500,500)

=item parent - the parent under which the new window should be opened (root)

=item mask - the user interface mask (StructureNotifyMask)

=item attributes - attributes to pass to glXChooseVisual

=back

Allowed 3d window types, case insensitive, are:

=over

=item glfw - use Perl OpenGL bindings and GLFW windows (no Tk)

=item glut - use Perl OpenGL bindings and GLUT windows (no Tk)

=item x11  - use Perl OpenGL (POGL) bindings with X11

=back

=cut

sub new {
  my($class,$options,$window_obj) = @_;
  my $opt = PDL::Options->new(default_options());
  $opt->incremental(1);
  $opt->options($options) if(defined $options);
  my $p = $opt->options;
  bless {Options => $p}, ref($class)||$class;
}

=head2 default_options

default options for object oriented methods

=cut

sub default_options{
   {  'x'     => 0,
      'y'     => 0,
      'width' => 500,
      'height'=> 500,
      'parent'=> 0,
      'mask'  => eval '&OpenGL::StructureNotifyMask',
      'steal' => 0,
      'attributes' => eval '[ &OpenGL::GLX_DOUBLEBUFFER, &OpenGL::GLX_RGBA ]',
   }
}

=head2 swap_buffers

OO interface to swapping frame buffers

=cut

sub swap_buffers {
  my ($this) = @_;
  die "swap_buffers: got object with inconsistent _GLObject info\n";
}

=head2 set_window

OO interface to setting the display window (if appropriate)

=cut

sub set_window {
  my ($this) = @_;
}

=head1 AUTHOR

Chris Marshall, C<< <devel dot chm dot 01 at gmail.com> >>

=head1 BUGS

Bugs and feature requests may be submitted through the PDL GitHub
project page at L<https://github.com/PDLPorters/pdl/issues> .

=head1 SUPPORT

PDL uses a mailing list support model.  The Perldl mailing list
is the best for questions, problems, and feature discussions with
other PDL users and PDL developers.

To subscribe see the page at L<http://pdl.perl.org/?page=mailing-lists>

=head1 ACKNOWLEDGEMENTS

TBD including PDL TriD developers and POGL developers...thanks to all.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Chris Marshall.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
