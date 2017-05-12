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
# Define arrays to hold data defining a spiral in the user coordinate
# system.
#
my $X = zeroes float, 476;
my $Y = zeroes float, 476;
#
# Define arrays to hold the numbers defining the viewport and window,
# as retrieved from GKS.
#
my $VIEW = zeroes float, 4;
my $WIND = zeroes float, 4;
#
# Turn off clipping at the edges of the viewport (which GKS does by
# default).
#
&NCAR::gsclip (0);
#
# Define the X and Y coordinates of a spiral in the user coordinate
# system.  It lies in a rectangular region bounded by the lines
# "X=100", "X=1000", "Y=100", and "Y=1000".
#
for my $I ( 1 .. 476 ) {
  my $THETA=.031415926535898*($I-1);
  set( $X, $I-1, 500.+.9*($I-1)*cos($THETA) );
  set( $Y, $I-1, 500.+.9*($I-1)*sin($THETA) );
}
#
# Loop through the possible values of 'LS'.
#
my $CHRS;
for my $ILS ( 1 .. 4 ) {
#
# Define the fractional coordinates of the left and right edges of the
# viewport.
#
  my $VPL=($ILS-1)/4.+.020;
  my $VPR=($ILS  )/4.-.020;
#
# For each of the possible values of 'LS', loop through the possible
# values of 'MI'.
#
  for my $IMI ( 1 .. 4 ) {
#
# Define the fractional coordinates of the bottom and top edges of the
# viewport.
#
    my $VPB=(4-$IMI)/4.+.059;
    my $VPT=(5-$IMI)/4.-.001;
#
# Outline the viewport.  PLOTIF expects fractional coordinates.
#
    &NCAR::plotif ($VPL,$VPB,0);
    &NCAR::plotif ($VPR,$VPB,1);
    &NCAR::plotif ($VPR,$VPT,1);
    &NCAR::plotif ($VPL,$VPT,1);
    &NCAR::plotif ($VPL,$VPB,1);
#
# Call SET to define the mapping from the user system to the plotter
# frame.  The SET call specifies 'MI' = 1 (since the value of argument
# 5 is less than that of argument 6 and the value of argument 7 is less
# that of argument 8).  The SETUSV call overrides this to obtain the
# desired value.
#
    &NCAR::set    ($VPL,$VPR,$VPB,$VPT,100.,1000.,100.,1000.,$ILS);
    &NCAR::setusv ('MI (MIRROR IMAGING FLAG)',$IMI);
#
# Call the routine CURVE to draw the spiral.
#
    &NCAR::curve  ($X,$Y,476);
#
# Label the curve.  First, write the values of 'MI' and 'LS'.  Note
# the use of CFUX and CFUY to map meaningful fractional coordinates
# to the user coordinates required by PLCHMQ.
#
    $CHRS = sprintf( '(\'MI=\'%1d\' LS=\'%1d\'', $IMI, $ILS );
    &NCAR::plchmq (&NCAR::cfux(.5*($VPL+$VPR)),&NCAR::cfuy($VPB-.0120),
                   substr( $CHRS, 0, 9 ),.012,0.,0.);
#
# Retrieve the values defining the window and viewport, using GKS
# calls.
#
    &NCAR::gqnt (1,my $IERR,$WIND,$VIEW);
#
# Write them out, too.
#
    $CHRS = sprintf( '(\'VP=\'%5.3f' . ( '(\',\'%5.3f))' x 3 ),
                     map { at( $VIEW, $_-1 ) } ( 1 .. 4 ) );
    substr( $CHRS, 3, 1, ' ' );
    substr( $CHRS, 9, 1, ' ' );
    substr( $CHRS,15, 1, ' ' );
    substr( $CHRS,21, 1, ' ' );
    &NCAR::plchmq (&NCAR::cfux(.5*($VPL+$VPR)),&NCAR::cfuy($VPB-.0320),
                   substr( $CHRS, 0, 26 ),.008,0.,0.);
    
    my $CHRS = sprintf( '(\'WD=\'%5.0f' . ( '(\',\'%5.0f))' x 3 ),
                        map { at( $WIND, $_-1 ) } ( 1 .. 4 ) );
    &NCAR::plchmq (&NCAR::cfux(.5*($VPL+$VPR)),&NCAR::cfuy($VPB-.0480),
                   substr( $CHRS, 0, 26 ),.008,0.,0.);
#
# End of loop through the values of 'MI'.
#
  }
#
# End of loop through the values of 'LS'.
#
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fcoord.ncgm';
