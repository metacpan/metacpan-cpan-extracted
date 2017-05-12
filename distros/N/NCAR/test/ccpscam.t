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

my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
my ( $MREG, $NREG ) = ( 50, 50 );
my $XREG = zeroes float, $MREG;
my $YREG = zeroes float, $NREG;
my $ZREG = zeroes float, $MREG, $NREG;
#
# Get data array
#
&GETDAT($XREG,$YREG,$ZREG,$MREG,$NREG);
#
# Open GKS and turn off clipping
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
&NCAR::gsclip(0);
#
# Call contour B&W fill routine
#
&CCPSCM($ZREG,$MREG,$NREG);
#
# Close frame and close GKS
#
&NCAR::frame();
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks;


sub CCPSCM {
  my ($ZREG,$MREG,$NREG) = @_;

  my ( $LRWK, $LIWK, $LMAP, $NWRK, $NOGRPS ) = ( 1000, 1000, 60000, 5000, 5 );
  my $RWRK = zeroes float, $LRWK;
  my $XWRK = zeroes float, $NWRK;
  my $YWRK = zeroes float, $NWRK;
  my $IWRK = zeroes long, $LIWK;
  my $MAP = zeroes long, $LMAP;
  my $IAREA = zeroes long, $NOGRPS;
  my $IGRP = zeroes long, $NOGRPS;

#     EXTERNAL SFILL
#     EXTERNAL CPDRPL
#
# Use regular or penalty labeling scheme so that contour labels can be
# boxed, and draw boxes.
#
  &NCAR::cpseti('LLP - LINE LABEL POSITIONING FLAG',2);
  &NCAR::cpseti('LLB - LINE LABEL BOX FLAG',1);
  &NCAR::cpseti('HLB - HIGH/LOW LABEL BOX FLAG',1);
#
# Set number of contour levels and initialize Conpack
#
  &NCAR::cprect ($ZREG, $MREG, $MREG, $NREG, $RWRK, $LRWK, $IWRK, $LIWK);
  &NCAR::cppkcl ($ZREG, $RWRK, $IWRK);
#
# Turn on line labeling and turn off area identifiers for all levels
#
  &NCAR::cpgeti('NCL - NUMBER OF CONTOUR LEVELS', my $NCL);
  for my $I ( 1 .. $NCL ) {
    &NCAR::cpseti('PAI - PARAMETER ARRAY INDEX',$I);
    &NCAR::cpseti('CLU - CONTOUR LEVEL USE FLAG',3);
    &NCAR::cpseti('AIA - AREA IDENTIFIER ABOVE',0);
    &NCAR::cpseti('AIB - AREA IDENTIFIER BELOW',0);
  }
#
# Add contour levels at 1.25 and 1.5, and set area ids so that 
# you can fill between them
#
  &NCAR::cpseti('NCL - NUMBER OF CONTOUR LEVELS',$NCL+2);
  &NCAR::cpseti('PAI - PARAMETER ARRAY INDEX',$NCL+1);
  &NCAR::cpsetr('CLV - CONTOUR LEVEL VALUE',1.25);
  &NCAR::cpseti('CLU - CONTOUR LEVEL USE FLAG',3);
  &NCAR::cpseti('AIA - AREA IDENTIFIER ABOVE',1);
  &NCAR::cpseti('AIB - AREA IDENTIFIER BELOW',2);
  &NCAR::cpseti('PAI - PARAMETER ARRAY INDEX',$NCL+2);
  &NCAR::cpsetr('CLV - CONTOUR LEVEL VALUE',1.5);
  &NCAR::cpseti('CLU - CONTOUR LEVEL USE FLAG',3);
  &NCAR::cpseti('AIA - AREA IDENTIFIER ABOVE',3);
  &NCAR::cpseti('AIB - AREA IDENTIFIER BELOW',1);
#
# Draw Perimeter
#
  &NCAR::cpback($ZREG, $RWRK, $IWRK);
#
# Initialize Areas
#
  &NCAR::arinam($MAP, $LMAP);
#
# Add contours to area map
#
  &NCAR::cpclam($ZREG, $RWRK, $IWRK, $MAP);
#
# Add label boxes to area map
#
  &NCAR::cplbam($ZREG, $RWRK, $IWRK, $MAP);
#
# Fill contours
#
  &NCAR::arscam($MAP, $XWRK, $YWRK, $NWRK, $IAREA, $IGRP, $NOGRPS, \&SFILL);
#
# Draw contours, masking label boxes
#
  &NCAR::cpcldm($ZREG, $RWRK, $IWRK, $MAP, \&NCAR::cpdrpl);
#
# Draw Labels
#
  &NCAR::cplbdr($ZREG, $RWRK, $IWRK);
#
# Write out the amount of space used in the area map
#
  &NCAR::cpgeti('RWU - REAL WORKSPACE USED',my $IRWU);
  &NCAR::cpgeti('IWU - INTEGER WORKSPACE USED',my $IWU);
  
  printf( STDERR "
Area map used %d  words.
Real workspace used %d words.
Integer workspace used %d words.
", at( $MAP, 0 )-at( $MAP, 5 )+at( $MAP, 4 ), $IRWU, $IWU );

}

sub SFILL {
  my ($XWRK,$YWRK,$NWRK,$IAREA,$IGRP,$NGRPS) = @_;
#
  my $ISCR = zeroes long, 5000;
  my $RSCR = zeroes float, 5000;

  my $IAREA3;
  for my $I ( 1 .. $NGRPS ) {
    if( at( $IGRP, $I-1 ) == 3 ) { $IAREA3 = at( $IAREA, $I-1 ); }
  }

  if( $IAREA3 == 1 ) {
#
# If the area is defined by 3 or more points, fill it
#
    &NCAR::sfsetr('SPACING',.006);
    &NCAR::sfnorm($XWRK,$YWRK,$NWRK,$RSCR,5000,$ISCR,5000);
  }
#   
# Otherwise, do nothing
#
}

sub GETDAT {
  my ($XREG,$YREG,$ZREG,$MREG,$NREG) = @_;

  my ( $NRAN, $LRWK, $LIWK ) = ( 30, 5000, 5000 );
  my $RWRK = zeroes float, $LRWK;
  my $IWRK = zeroes long, $LIWK;

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
  for my $I ( 1 .. $MREG ) {
    set( $XREG, $I-1, $XMIN + ($XMAX - $XMIN)*$XDELTA[$I-1] );
  }
#
  for my $I  ( 1 .. $NREG ) {
    set( $YREG, $I-1, $YMIN + ($YMAX - $YMIN)*$XDELTA[$I-1] );
  }
#      
# Interpolate data onto a regular grid
#
  &NCAR::idsfft (1,$NRAN,$XRAN,$YRAN,$ZRAN,$MREG,$NREG,$MREG,$XREG,$YREG,$ZREG,$IWRK,$RWRK);

}
   
rename 'gmeta', 'ncgm/ccpscam.ncgm';
