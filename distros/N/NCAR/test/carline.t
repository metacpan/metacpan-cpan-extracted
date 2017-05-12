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
my ( $LMAP, $NGEO, $NPTS, $NGRPS ) = ( 150000, 43, 50, 2 );
my $NWRK = 1000;

my $MAP = zeroes long, $LMAP;
my $IAREA = zeroes long, $NGRPS;
my $IGRP = zeroes long, $NGRPS;
my $XCNTR = zeroes float, $NPTS;
my $YCNTR1 = zeroes float, $NPTS;
my $YCNTR2 = zeroes float, $NPTS;
my $YCNTR3 = zeroes float, $NPTS;
my $YCNTR4 = zeroes float, $NPTS;
my $YCNTR5 = zeroes float, $NPTS;
my $XWRK = zeroes float, $NWRK;
my $YWRK = zeroes float, $NWRK;

#     EXTERNAL MASK

my $XGEO = float [
          .63, .12, .05, .07, .10, .04, .19, .31, .31, .41,
          .39, .47, .64, .63, .70, .66, .67, .69, .76, .92,
          .95, .69, .64, .53, .53, .60, .63, .63, .72, .74,
          .79, .75, .75, .80, .75, .70, .68, .64, .63, .55,
          .55, .63, .63 ];
my $YGEO = float [
          .94, .95, .92, .85, .83, .78, .84, .75, .69, .58,
          .64, .55, .47, .37, .30, .05, .03, .05, .13, .26,
          .38, .52, .50, .57, .63, .63, .59, .64, .72, .71,
          .75, .75, .77, .78, .85, .83, .86, .86, .77, .80,
          .86, .90, .94 ];
my $X = float [ 
          .10, .22, .25, .25, .25, .50,
          .30, .47, .50, .77, .75, .68 ];
my $Y = float [
          .98, .70, .55, .38, .18, .18,
          .90, .85, .70, .35, .18, .05 ];
#     
# Generate Contour lines
#     
for my $J ( 1 .. $NPTS ) {
  my $DIST = ($J-1)/($NPTS-1);
  set( $XCNTR , $J-1, $DIST );
  set( $YCNTR1, $J-1, .1*cos(4.*3.14*$DIST)+.15 );
  set( $YCNTR2, $J-1, .1*cos(4.*3.14*$DIST)+.30 );
  set( $YCNTR3, $J-1, .1*cos(4.*3.14*$DIST)+.50 );
  set( $YCNTR4, $J-1, .1*cos(4.*3.14*$DIST)+.70 );
  set( $YCNTR5, $J-1, .1*cos(4.*3.14*$DIST)+.85 );
}
#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Set up color table and set Dash pattern to solid
#
&COLOR ($IWKID);
&NCAR::dashdb(65535);
#
# Outline continents in red
#
&NCAR::gsplci (1);
&NCAR::curve ($XGEO,$YGEO,$NGEO);
#
# Initialize Areas
#
&NCAR::arinam ($MAP,$LMAP);
#
# Add continents to area map in group 1.
#
&NCAR::aredam ($MAP, $XGEO, $YGEO, $NGEO, 1, 2, 1);
#
# Add contours to area map in group 3.
#
&NCAR::aredam ($MAP, $XCNTR, $YCNTR1, $NPTS, 3, 2, 1);
&NCAR::aredam ($MAP, $XCNTR, $YCNTR2, $NPTS, 3, 3, 2);
&NCAR::aredam ($MAP, $XCNTR, $YCNTR3, $NPTS, 3, 4, 3);
&NCAR::aredam ($MAP, $XCNTR, $YCNTR4, $NPTS, 3, 5, 4);
&NCAR::aredam ($MAP, $XCNTR, $YCNTR5, $NPTS, 3, 6, 5);
#
# Write out area and group identifiers for each area, using red for
# geographic identifiers, and green for contour identifiers.
#
for my $I ( 1 .. 12 ) {
  &NCAR::argtai($MAP, at( $X, $I-1 ), at( $Y, $I-1 ), $IAREA, $IGRP, $NGRPS, my $NAI, 1);
  for my $J ( 1 .. 2 ) {
    my $STRING = sprintf( "A(%1d)=%1d G(%1d)=%1d\n", 
                          $J, at( $IAREA, $J-1 ),
                          $J, at( $IGRP, $J-1 ) );
    if( at( $IGRP, $J-1 ) == 1 ) {
      &NCAR::gsplci(1);
      &NCAR::plchhq (at( $X, $I-1 ), at( $Y, $I-1 ), $STRING, .01, 0., 0.);
    }
    if( at( $IGRP, $J-1 ) == 3 ) {
      &NCAR::gsplci(6);
      &NCAR::plchhq (at( $X, $I-1 ), at( $Y, $I-1 ), $STRING, .01, 0., 0.);
    }
  }
}
#
# Draw contour lines only over water
#
&NCAR::gsplci(7);
&NCAR::ardrln($MAP,$XCNTR,$YCNTR1,$NPTS,$XWRK,$YWRK,$NWRK,$IAREA,$IGRP,$NGRPS,\&MASK);
&NCAR::ardrln($MAP,$XCNTR,$YCNTR2,$NPTS,$XWRK,$YWRK,$NWRK,$IAREA,$IGRP,$NGRPS,\&MASK);
&NCAR::gslwsc(2.);
&NCAR::gsplci(2);
&NCAR::ardrln($MAP,$XCNTR,$YCNTR3,$NPTS,$XWRK,$YWRK,$NWRK,$IAREA,$IGRP,$NGRPS,\&MASK);
&NCAR::gslwsc(1.);
&NCAR::gsplci(7);
&NCAR::ardrln($MAP,$XCNTR,$YCNTR4,$NPTS,$XWRK,$YWRK,$NWRK,$IAREA,$IGRP,$NGRPS,\&MASK);
&NCAR::ardrln($MAP,$XCNTR,$YCNTR5,$NPTS,$XWRK,$YWRK,$NWRK,$IAREA,$IGRP,$NGRPS,\&MASK);
      
&NCAR::frame();
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();


sub COLOR {
  my ($IWKID) = @_;
#
# Define color table
#
# Background is white to show up on both paper and terminal
#
  &NCAR::gscr($IWKID,0,1.,1.,1.);
#
# Red
#
  &NCAR::gscr($IWKID,1,.7,0.,0.);
#
# Green
#
  &NCAR::gscr($IWKID,2,0.,.7,0.);
#
# Yellow
#
  &NCAR::gscr($IWKID,3,.7,.7,0.);
#
# Blue
#
  &NCAR::gscr($IWKID,4,0.,0.,.7);
#
# Magenta
#
  &NCAR::gscr($IWKID,5,.7,0.,.7);
#
# Aqua
#
  &NCAR::gscr($IWKID,6,0.,.7,.7);
#
# Black
#
  &NCAR::gscr($IWKID,7,0.,0.,0.);
}

sub MASK {
  my ($XC,$YC,$MCS,$IAREA,$IGRP,$NGRPS) = @_;
      
  my $IDGEO=-1;
#
# Retrieve geographic area identifier
#
  for my $I ( 1 .. $NGRPS ) {
    if( at( $IGRP, $I-1 ) == 1 ) { $IDGEO = at( $IAREA, $I-1 ); }
  }
#
# If the contour segment is over water, then draw it
#
  if( $IDGEO == 1 ) {
    &NCAR::curved($XC,$YC,$MCS);
  }
#
# Otherwise, don't draw the line - mask it.
#
}

   
rename 'gmeta', 'ncgm/carline.ncgm';
