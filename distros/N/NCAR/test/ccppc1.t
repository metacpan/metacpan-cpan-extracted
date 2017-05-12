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
use NCAR::Test qw( bndary gendat drawcl );
use strict;
   
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
my ( $LRWK, $LIWK, $LMAP ) = ( 3500, 4000, 75000 );
my ( $MREG, $NREG ) = ( 50, 50 );
my $X = zeroes float, $MREG;
my $Y = zeroes float, $NREG;
my $ZREG = zeroes float, $MREG, $NREG;
my $RWRK = zeroes float, $LRWK;
my $IWRK = zeroes long, $LIWK;
my $MAP = zeroes long, $LMAP;

#     EXTERNAL CPDRPL

&GETDAT ($X, $Y, $ZREG, $MREG, $NREG, $RWRK, $IWRK, $LRWK, $LIWK);
#
# Open GKS
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Initialize Areas
#
&NCAR::arinam($MAP,$LMAP);
#
# Choose which labelling scheme will be used.
#
&NCAR::cpseti('LLP - LINE LABEL POSITIONING FLAG',3);
#
# Set the gradient parameter to label steep slopes
#
&NCAR::cpsetr('PC1 - PENALTY SCHEME CONSTANT 1',3.0);
#
# Initialize Conpack
#
&NCAR::cprect($ZREG, $MREG, $MREG, $NREG, $RWRK, $LRWK, $IWRK, $LIWK);
#
# Force Conpack to chose contour levels
#
&NCAR::cppkcl($ZREG, $RWRK, $IWRK);
#
# Modify Conpack chosen parameters
#
&NCAR::cpgeti('NCL - NUMBER OF CONTOUR LEVELS',my $NCONS);
for my $I ( 1 .. $NCONS ) {
  &NCAR::cpseti('PAI - PARAMETER ARRAY INDEX',$I);
#
# Force every line to be labeled.
#
  &NCAR::cpseti('CLU - CONTOUR LEVEL USE FLAG',3);
}
#
# Add contours to area map
#
&NCAR::cpclam($ZREG, $RWRK, $IWRK, $MAP);
#
# Add labels to area map
#
&NCAR::cplbam($ZREG, $RWRK, $IWRK, $MAP);
#
# Draw Perimeter
#
&NCAR::cpback($ZREG, $RWRK, $IWRK);
#
# Draw Labels
#
&NCAR::cplbdr($ZREG,$RWRK,$IWRK);
#
# Draw Contours
#
&NCAR::cpcldm($ZREG,$RWRK,$IWRK,$MAP,\&NCAR::cpdrpl);
#
# Close frame and close GKS
#
&NCAR::frame();
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks;


sub GETDAT {
  my ($X,$Y,$Z,$M,$N,$RWRK,$IWRK,$LRWK,$LIWK) = @_;

  my $NRAN=30;

  my $XRAN = float [ 
              12., 60., 14., 33.,  8., 12., 43., 57., 22., 15.,
              19., 12., 64., 19., 15., 55., 31., 32., 33., 29.,
              18.,  1., 18., 42., 56.,  9.,  6., 12., 44., 19. ];
  my $YRAN = float [
               1.,  2.,  3., 53.,  7., 11., 13., 17., 19., 49.,
               1., 31., 37.,  5.,  7., 47., 61., 17.,  5., 23.,
              29.,  3.,  5., 41., 43.,  9., 13., 59.,  1., 67. ];
  my $ZRAN = float [ 
              1.0, 1.5, 1.7, 1.4, 1.9, 1.0, 1.5, 1.2, 1.8, 1.4,
              1.8, 1.7, 1.9, 1.5, 1.2, 1.1, 1.3, 1.7, 1.2, 1.6,
              1.9, 1.0, 1.6, 1.3, 1.4, 1.8, 1.7, 1.5, 1.1, 1.0 ];
  my @XDELTA = (
                 .00,.02,.04,.06,.08,.10,.12,.14,.16,.18,.20,
                 .22,.24,.26,.28,.30,.32,.34,.36,.38,.40,.42,
                 .44,.46,.48,.50,.52,.54,.56,.58,.60,.62,.64,
                 .66,.68,.70,.72,.74,.76,.78,.80,.82,.84,.86,
                 .88,.90,.92,.94,.96,.98 );
#
#  Set the min and max data values.
#
  my $XMIN = 0.0;
  my $XMAX = 65.0;
  my $YMIN =  0.0;
  my $YMAX = 68.0;
#
# Choose the X and Y coordinates for interpolation points on the 
# regular grid.
#
  for my $I ( 1 .. $M ) {
    set( $X, $I-1, $XMIN + ($XMAX - $XMIN)*$XDELTA[$I-1] );
  }
#
  for my $I ( 1 .. $N ) {
    set( $Y, $I-1, $YMIN + ($YMAX - $YMIN)*$XDELTA[$I-1] );
  }
#
# Interpolate data onto a regular grid
#
  &NCAR::idsfft (1,$NRAN,$XRAN,$YRAN,$ZRAN,$M,$N,$M,$X,$Y,$Z,$IWRK,$RWRK);
      
}

rename 'gmeta', 'ncgm/ccppc1.ncgm';
