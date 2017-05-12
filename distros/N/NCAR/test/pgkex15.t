# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use NCAR;
ok(1); # If we made it this far, we're ok.;

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
unlink( 'gmeta' );

use PDL;
use NCAR::Test;
use strict;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
#  Define colors.
#
&NCAR::gscr(1,0,1.,1.,1.);
&NCAR::gscr(1,1,0.,0.,1.);
&NCAR::gscr(1,2,.4,.0,.4);
#
#  Replicate the small filled area over the entire plot.
#
for( my $J = 1; $J <= 8; $J += 2 ) {;
  for( my $I = 1; $I <= 10; $I += 2 ) {;
    &drwso(.05+($I-1)*.1,.14+($J-1)*.1,.1,0.);
    &drwso(.15+($I-1)*.1,.14+($J-1)*.1,.1,180.);
    &drwso(.05+($I-1)*.1,.24+($J-1)*.1,.1,180.);
    &drwso(.15+($I-1)*.1,.24+($J-1)*.1,.1,0.);
  }
}
#
#  Label the plot using Plotchar.
#
&NCAR::pcseti( 'FN', 25 );
&NCAR::pcseti( 'CC', 2 );
&NCAR::plchhq(.5,.94,'Filled areas',.035,0.,0.);


sub drwso {
  my ($X,$Y,$SCALE,$ANGD) = @_;
#
#  Draw the fill area at coordinate (X,Y) at angle ANGD (in degrees)
#  and scaled by SCALE.  Using a higher level of GKS one could use
#  segment transformations to do the rotation, translation, and
#  scaling, but it is done directly here.
#
  my $ID=16;
  my $H=1.;
#
#  Coordinates for the basic fill pattern.
#
  my @XA = (
        0.000000,  0.130602,  0.500000,  0.315301,
        0.500000,  0.315301,  0.130602,  0.130602,
        0.000000, -0.130602, -0.130602, -0.315301,
       -0.500000, -0.315301, -0.500000, -0.130602,
  );
  my @YA = (
       -0.500000, -0.369398, -0.369398, -0.184699,
        0.000000,  0.184699,  0.000000,  0.369398,
        0.500000,  0.369398,  0.000000,  0.184699,
        0.000000, -0.184699, -0.369398, -0.369398,
  );
  my $RADC = .0174532;
  
#
#  Convert the angle to radians.
#
  my $ANGR = $RADC*$ANGD;
#
#  Translate, scale, and rotate the object so that its center is
#  at (X,Y).
#
  my $XB = zeroes float, $ID+1;
  my $YB = zeroes float, $ID+1;
  for my $K ( 1 .. $ID ) {
    set( $XB, $K - 1, $X+$SCALE*($XA[$K-1]*cos($ANGR)-$YA[$K-1]*sin($ANGR)) );
    set( $YB, $K - 1, $Y+$SCALE*($YA[$K-1]*sin($ANGR)+$YA[$K-1]*cos($ANGR)) );
  }
  &NCAR::gsfais(1);
  &NCAR::gsfaci(1);
  set( $XB, $ID, at( $XB, 1 ) );
  set( $YB, $ID, at( $YB, 1 ) );
  &NCAR::gfa($ID,$XB,$YB);
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/pgkex15.ncgm';
