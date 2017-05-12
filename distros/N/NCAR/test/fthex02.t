# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use NCAR;
use NCAR::Test qw( min );
ok(1); # If we made it this far, we're ok.;

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
unlink( 'gmeta' );

use PDL;
use NCAR::Test qw( bndary gendat drawcl );
use strict;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
# Declare an array in which to put an eye position for THREED.
#
my $PEYE;
#
# Define a character variable in which to form numeric labels.
#
my $CHRS;
#
# Declare a function W(U,V) to be used in the example.
#
sub WFUN {
  my ( $U, $V ) = @_;
  return
      .5+.25*sin(5.*$U)+.25*cos(5.*$V);
}
#
# Make the tick marks drawn by PERIM3 different from the default.
#
&NCAR::tick43 (12,8,24,16,48,32);
#
# Define the boundaries of the box to be projected from 3-space to
# 2-space.
#
my $UMIN=0.;
my $UMAX=1.;
my $VMIN=0.;
my $VMAX=1.;
my $WMIN=0.;
my $WMAX=1.;
#
# Define the position of the eye.
#
$PEYE = float [ 6., 4., 5. ];
#
# Initialize THREED.
#
&NCAR::set3 (.1,.9,.1,.9,$UMIN,$UMAX,$VMIN,$VMAX,$WMIN,$WMAX,$PEYE);
#
# Draw perimeters in each of the three coordinate planes.
#
&NCAR::perim3 (10,2,10,2,1,0.);
&NCAR::perim3 (10,2,10,2,2,0.);
&NCAR::perim3 (10,4,10,4,3,0.);

#
# Put some labels on the plot.  First, the U axis.
#
&NCAR::pwrzt (.5,0.,1.1,'U',1,3,-1,+3,0);
#

for my $ILAB ( 1 .. 10 ) {
  my $UPOS=$ILAB/10.;
  $CHRS = sprintf( '%8.1f', $UPOS );
  my $IBEG=0;
  my $IEND=0;
  for my $ICHR ( 1 .. 8 ) {
    if( substr( $CHRS, $ICHR-1, 1 ) ne ' ' ) {
      if( $IBEG == 0 ) {
        $IBEG=$ICHR;
      }
      $IEND=$ICHR;
    }
  }
  if( substr( $CHRS, $IBEG-1, 1 ) eq '0' ) {
    $IBEG=&NCAR::Test::min($IBEG+1,$IEND);
  }
  &NCAR::pwrzt ($UPOS,0.,1.05,substr($CHRS,$IBEG-1,$IBEG-$IEND+1),$IEND-$IBEG+1,3,-1,+3,0);
}
#
# Next, the V axis.
#
&NCAR::pwrzt (0.,.5,1.1,'V',1,3,+2,+3,0);
#
for my $ILAB ( 1 .. 10 ) {
  my $VPOS=($ILAB)/10.;
  my $CHRS = sprintf( '%8.1f', $VPOS );
  my $IBEG=0;
  my $IEND=0;
  for my $ICHR ( 1 .. 8 ) {
    if( substr( $CHRS, $ICHR-1, 1 ) ne ' ' ) {
      if( $IBEG == 0 ) {
        $IBEG = $ICHR;
      }
      $IEND=$ICHR;
    }
  }
  if( substr( $CHRS, $IBEG-1, 1 ) eq '0' ) {
    $IBEG=&NCAR::Test::min($IBEG+1,$IEND);
  }
  &NCAR::pwrzt (0.,$VPOS,1.05, substr( $CHRS, $IBEG, $IEND-$IBEG+1 ),$IEND-$IBEG+1,3,+2,+3,0);
}
#
# Finally, the W axis.
#
&NCAR::pwrzt (1.2,0.,.5,'W',1,3,-1,+3,1);
#
for my $ILAB ( 0 .. 10 ) {
  my $WPOS=($ILAB)/10.;
  my $CHRS = sprintf( '%8.1f', $WPOS );
  my $IBEG=0;
  my $IEND=0;
  for my $ICHR ( 1 .. 8 ) {
    if( substr( $CHRS, $ICHR-1, 1 ) ne ' ' ) {
      if( $IBEG == 0 ) {
        $IBEG=$ICHR;
      }
      $IEND=$ICHR;
    }
  }
  if( substr( $CHRS, $IBEG-1, 1 ) eq '0' ) {
    $IBEG=&NCAR::Test::min($IBEG+1,$IEND);
  }
  &NCAR::pwrzt (1.05,0.,$WPOS,substr( $CHRS, $IBEG-1, $IEND-$IBEG+1 ),$IEND-$IBEG+1,3,-1,+3,1);
}
#
# Using POINT3, draw grids inside the perimeters drawn by PERIM3.
#
for my $I ( 1 .. 11 ) {
  my $PTMP=($I-1)/10.;
  for my $J ( 1 .. 101 ) {
    my $QTMP=($J-1)/100.;
    &NCAR::point3 ($PTMP,$QTMP,0.);
    &NCAR::point3 ($QTMP,$PTMP,0.);
    &NCAR::point3 ($PTMP,0.,$QTMP);
    &NCAR::point3 ($QTMP,0.,$PTMP);
    &NCAR::point3 (0.,$PTMP,$QTMP);
    &NCAR::point3 (0.,$QTMP,$PTMP);
  }
}
#
# Double the line width and draw a wire-frame representation of the
# surface defined by the function WFUN, using the routines FRST3 and
# VECT3.
#
#
for my $I ( 1 .. 11 ) {
  my $UTMP=($I-1)/10.;
  &NCAR::frst3 ($UTMP,0.,&WFUN($UTMP,0.));
  for my $J ( 2 .. 11 ) {
    my $VTMP=($J-1)/10.;
    &NCAR::vect3 ($UTMP,$VTMP,&WFUN($UTMP,$VTMP));
  }
}
#
 for my $J ( 1 .. 11 ) {
  my $VTMP=($J-1)/10.;
  &NCAR::frst3 (0.,$VTMP,&WFUN(0.,$VTMP));
  for my $I ( 2 .. 11 ) {
     my $UTMP=($I-1)/10.;
     &NCAR::vect3 ($UTMP,$VTMP,&WFUN($UTMP,$VTMP));
   }
 }
#
# Double the line width and put a little set of axes at each point on
# the surface.
#
# 
&NCAR::plotif (0.,0.,2);
&NCAR::gslwsc (2.);
for( my $I = 1; $I <= 21; $I += 2 ) {
    my $UTMP=($I-1)/20.;
  for( my $J = 1; $J <= 21; $J += 2 ) {
    my $VTMP=($J-1)/20.;
    my $WTMP=&WFUN($UTMP,$VTMP);
    &NCAR::line3 ($UTMP-.04,$VTMP,$WTMP,$UTMP+.04,$VTMP,$WTMP);
    &NCAR::line3 ($UTMP,$VTMP-.04,$WTMP,$UTMP,$VTMP+.04,$WTMP);
    &NCAR::line3 ($UTMP,$VTMP,$WTMP-.04,$UTMP,$VTMP,$WTMP+.04);
  }
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/fthex02.ncgm';
