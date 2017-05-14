###  $Id: glTestWindow.pm 372 2008-08-11 13:05:50Z duncan $
####------------------------------------------
## @file
# Test driver for objects

package TestWindow;

use strict;
use warnings;

use OpenGL ':all';
use Tk;

use constant PI => 4*atan2(1,1); # 3.14159;
use constant RADIANS => PI/180.0;

my $width = 400;
my ($oldx,$oldy) = (-1,-1);
my ($oldx2,$oldy2) = (-1,-1);
my ($oldx3,$oldy3) = (-1,-1);
my ($control1,$control2,$control3,$control4,$control5,$control6)= (0,0,0,0,0,0);
my $spin = 0;
my $spinRate = 1;
our $tkTime = 25;
our ($cx,$cy,$cz,$lpx,$lpy,$lpz) = (-10, 5, -10, -9,5,-10);
our ($viewX,$viewY,$viewZ);
our ($viewRot,$viewNod)=(0,0);

my $mw;
my $is_pm;
my %cb;
my ($v4,$v5,$v6);

my @objects;

sub add_thing {
  my @things = @_;
  push @objects, @things;
}


## @fn $ testWind
# Run the display
sub testWind { warn 'TestWindow::testWind() ',join ':', caller;
  my ($offset,$view) = @_;
  $offset = -10 if !defined($offset);
  $view = -45.0 if !defined($view);

  OpenGL::glpOpenWindow(width=>$width, height=>$width,
			mask => StructureNotifyMask | KeyPressMask | PointerMotionMask | ButtonMotionMask,
	    #		mask => StructureNotifyMask|KeyPressMask,
	    #		attributes=>[GLX_RGBA,GLX_DOUBLEBUFFER,
            #			     GLX_DEPTH_SIZE,16],
		       );
  OpenGL::glutInitDisplayMode(GLUT_RGBA | GLUT_ALPHA | GLUT_DOUBLE |GLUT_DEPTH);

###
### Setup Tk Window
###
  $mw = MainWindow->new(-title=>'Test Window Control',
			-height=>40, -width=> 300,
			#-x=>100,
			#-y=>400,
		       );
  $mw->MoveToplevelWindow(100,400);
  my $base2 = $mw->Frame(-height=>40, -width=> 300,
			 -relief=>'sunken', -bd=>2)->grid;

  my $l1 = $base2->Label(-text=>"Rotate: ")->grid(-row=>0, -column=>0);
  my $s1 = $base2->Spinbox(-increment=>1, -from=> 0, -to=>360,
			   -textvariable=> \$viewRot,
			  )->grid(-row=>0, -column=>1);
  my $l2 = $base2->Label(-text=>"Nod: ")->grid(-row=>1, -column=>0);
  my $s2 = $base2->Spinbox(-increment=>1, -from=> -90, -to=>90,
			   -textvariable=> \$viewNod,
			  )->grid(-row=>1, -column=>1);
  my $l3 = $base2->Label(-text=>"SpinRate: ")->grid(-row=>2, -column=>0);
  my $s3 = $base2->Spinbox(-increment=>0.1, -from=> -360, -to=>360,
			   -textvariable=> \$spinRate,
			  )->grid(-row=>2, -column=>1);
  my $l4 = $base2->Label(-text=>"X: ")->grid(-row=>3, -column=>0);
  my $s4 = $base2->Spinbox(-increment=>1, -from=> -90, -to=>90,
			   -textvariable=> \$cx,
			  )->grid(-row=>3, -column=>1);
  my $l5 = $base2->Label(-text=>"Y: ")->grid(-row=>4, -column=>0);
  my $s5a= $base2->Spinbox(-increment=>1, -from=> -90, -to=>90,
			   -textvariable=> \$cy,
			  )->grid(-row=>4, -column=>1);
  my $l6 = $base2->Label(-text=>"Z: ")->grid(-row=>5, -column=>0);
  my $s6 = $base2->Spinbox(-increment=>1, -from=> -90, -to=>90,
			   -textvariable=> \$cz,
			  )->grid(-row=>5, -column=>1);

  my $l8 = $base2->Label(-text=>"Look X: ")->grid(-row=>6, -column=>0);
  $v4 = $base2->Text(-relief =>'sunken',-width=>10,-height=>1)
                    ->grid(-row=>6, -column=>1);
  $v4->insert('end',$viewX);
  $v4->bindtags(undef);
  my $l9 = $base2->Label(-text=>"Look Y: ")->grid(-row=>7, -column=>0);
  $v5 = $base2->Text(-relief => 'sunken',-width=>10,-height=>1			)->grid(-row=>7, -column=>1);
  $v5->insert('end',$viewY);
  my $l10 = $base2->Label(-text=>"Look Z: ")->grid(-row=>8, -column=>0);
  $v6 = $base2->Text(-relief => 'sunken',-width=>10,-height=>1
			)->grid(-row=>8, -column=>1);
  $v6->insert('end',$viewZ);

  my $l7 = $base2->Label(-text=>"Tk Time: ")->grid(-row=>9, -column=>0);
  my $s5 = $base2->Spinbox(-increment=>0.1, -from=> -360, -to=>360,
			   -textvariable=> \$tkTime,
			  )->grid(-row=>9, -column=>1);

  $mw->Button(-text => 'Quit', -command => \&Tk::exit)->grid;

  glShadeModel (GL_FLAT);
  glEnable(GL_DEPTH_TEST);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glFrustum (-1.0, 1.0, -1.0, 1.0, 1.5, 500.0);
  glMatrixMode(GL_MODELVIEW);

  glColor3f(1,0,0);
  glClearColor(0,0,0.3,1);

  my $w=100.0;
  my $t= time;
  my $p= $t-1;
  #our ($rin,$win,$ein);
  #$rin=$win=$ein='';

  my $spf = 1;
  #  our $spin=0;
  my %kcb;
  my @e;
  our $rout;
  my $s;

  ### Setup responses to user input

#  $cb{&ConfigureNotify} = sub  { die join ':', caller;  my($e,$w,$h) = @_;
#				glViewport(0,0,$w-20,$h);
#				# print "viewport $w,$h\n";
#			      };
#  $cb{&KeyPress} = sub  { die join ':', caller; 	# print "@_[1] ",ord(@_[1])," keypress @_\n";
#    my($ss); &$ss($_[1]) if ($ss=$kcb{$_[1]}); };
#  $kcb{'q'} = $kcb{'Q'} = $kcb{"\033"} = sub  { die join ':', caller;  print "Good-Bye\n"; exit 0;};

  $is_pm = OpenGL::_have_glp && ! OpenGL::_have_glx;

  ###
  ### Display Loop
  ###
  #  while (1) {

  timeTick(#$game->team,$game->currmap
	  );

  Tk::MainLoop();
}

sub display_loop {
  my $rotRad = $viewRot*RADIANS;
  $viewX = $cx+sin($rotRad)*1.0;
  $v4->delete('1.0','end');
  $v4->insert('1.0',$viewX);

  $viewZ = $cz+cos($rotRad)*1.0;
  $v5->delete('1.0','end');
  $v5->insert('1.0',$viewZ);

  $viewY = $cy+sin($viewNod*RADIANS)*1.0;
  $v6->delete('1.0','end');
  $v6->insert('1.0',$viewY);

  #foreach my $i (1..4) {
  #    $spf = ($spf*$w + $t-$p) /($w+1.0);
  #    my $fps = ($spf)?1.0/$spf:0;
  #    $p=$t;
  #    $t= time;
  my $p;
  my @e;
  # Accept and react to user input
  while ($p = XPending) {
    @e = glpXNextEvent;
    my $s;
    &$s(@e) if ($s = $cb{$e[0]});
  }
  my ($px,$py,$pm) = glpXQueryPointer;
  # Test that mouse cursor is in this application
  # TODO and that the application is on top
  if ($px>0 && $py>0 && $px <$width && $py <$width) {
    my $rot = 0;
    if ($pm & Button1Mask) {
      if ($oldx != -1) {
	$control1 = $px-$oldx;
      }
      $oldx = $px;
    }
    if ($pm & Button3Mask) {
      if ($oldx3 != -1) {
	$control3 = $px-$oldx3;
      }
      $oldx3 = $px;
    }
    if (($pm & Button2Mask)  && ( $pm & (ShiftMask))) {

    }

    if ($pm & Button2Mask) {
      if ($oldx2 != -1) {
	$control2 = $px-$oldx2;
      }
      $oldx2 = $px;

    }
  }

  my ($rin,$rout);
  $rin = '';
  vec($rin,0,1) = 1;
  if (!$is_pm && select($rout=$rin,undef,undef,0)) {
    $_=<> || die "End Of File";
    eval;
  }

  foreach my $x (@objects) {
    $x->move;			# move each object 1 time step
    #$x->print;
  }
  ###
  ### Display the scene
  ###
  glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
  glLoadIdentity ();
  gluLookAt($cx,$cy,$cz,$viewX,$viewY,$viewZ,0,1.0,0);
  select(undef, undef, undef, 0.06); ##Delay

  # set the viewpoint
  #    $offset += $control1;
#XXX  $view += $control2;
  $spin += $control3;
  #glTranslatef (0.0, -3.0, $offset);
  #glRotatef($view, 1.0,0.0,0.0);
  $spin += $spinRate;
  if ($spin>360) {
    $spin-=360;
  }
  #glRotatef($spin, 0.0,1.0,0.0);

  foreach my $x (@objects) {
    $x->draw(GL_RENDER);	# draw each object
    $x->move;
  }
  glFlush();
  glXSwapBuffers;
}

sub timeTick { #die join ':', caller;
  my $m = shift;
  # warn $m;
  #$map1 = $m;
  select(undef, undef, undef, 0.06); ##Delay
  # ensure that nav and Tk get enough time
  #nav($map1);
  display_loop;
  $mw->after($tkTime=>[\&timeTick,
		       #$map1
		      ]);
}
#==================================================================
###
### Test Driver
###

if (!defined(caller())) {
  package main;

  #require glChest;
  require glGrid;

  #my $chest1 = Chest->new(x=>0,z=>0,angle=>0,target_ang=>60);
  my $g = Grid->new;
  &TestWindow::add_thing($g);
  &TestWindow::testWind(-8,+30);
}

1;

__END__

=head1 NAME

TestWindow -- Testing tool

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@rejiquar.com>E<gt>,
and Rob Duncan E<lt>F<duncan@rejiquar.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars, All rights reserved.

=head1 LICENSE

This software is provided under the Perl License.  It may be distributed
and revised according to the terms of that license.

=cut
