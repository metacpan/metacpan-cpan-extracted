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
   
#
#  Define error file, Fortran unit number, and workstation type,
#  and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
my ( $LMAP, $NMAP, $NPTS, $NCNTR, $NGRPS ) = ( 5000, 43, 50, 5, 2 );
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
      
my $XGEO = float [
          .63, .12, .05, .07, .10, .04, .19, .31, .31, .41,
          .39, .47, .64, .63, .70, .66, .67, .69, .76, .92,
          .95, .69, .64, .53, .53, .60, .63, .63, .72, .74,
          .79, .75, .75, .80, .75, .70, .68, .64, .63, .55,
          .55, .63, .63 ];
my $YGEO  = float [
          .94, .95, .92, .85, .83, .78, .84, .75, .69, .58,
          .64, .55, .47, .37, .30, .05, .03, .05, .13, .26,
          .38, .52, .50, .57, .63, .63, .59, .64, .72, .71,
          .75, .75, .77, .78, .85, .83, .86, .86, .77, .80,
          .86, .90, .94 ];
my $XPERIM = float [ 0.0, 1.0, 1.0, 0.0, 0.0 ];
my $YPERIM = float [ 0.0, 0.0, 1.0, 1.0, 0.0 ];
my $X = float [ 
          .10, .22, .25, .25, .25, .50,
          .30, .47, .50, .77, .75, .68 ];
my $Y = float [
          .98, .70, .55, .38, .18, .18,
          .90, .85, .70, .35, .18, .05 ];
      
#     EXTERNAL FILL
      
set( $XCNTR,  0, 0.0  );
set( $YCNTR1, 0, 0.25 );
set( $YCNTR2, 0, 0.40 );
set( $YCNTR3, 0, 0.60 );
set( $YCNTR4, 0, 0.80 );
set( $YCNTR5, 0, 0.95 );
for my $J ( 2 .. $NPTS ) {
  my $DIST = $J/$NPTS;
  set( $XCNTR,  $J-1, $DIST );
  set( $YCNTR1, $J-1, .1*cos((4*3.14*$DIST))+.15 );
  set( $YCNTR2, $J-1, .1*cos((4*3.14*$DIST))+.30 );
  set( $YCNTR3, $J-1, .1*cos((4*3.14*$DIST))+.50 );
  set( $YCNTR4, $J-1, .1*cos((4*3.14*$DIST))+.70 );
  set( $YCNTR5, $J-1, .1*cos((4*3.14*$DIST))+.85 );
}

#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);

&COLOR($IWKID);
#
# Set the fill area option to solid
#
&NCAR::gsfais(1);
#
# Initialize Areas
#
&NCAR::arinam ($MAP,$LMAP);
#
# Add continents to area map in group 1.
#
&NCAR::aredam ($MAP, $XGEO, $YGEO, $NMAP, 1, 2, 1);
#
# Add contours and perimeter to area map in group 3.
#
&NCAR::aredam ($MAP, $XCNTR, $YCNTR1, $NPTS, 3, 2, 1);
&NCAR::aredam ($MAP, $XCNTR, $YCNTR2, $NPTS, 3, 3, 2);
&NCAR::aredam ($MAP, $XCNTR, $YCNTR3, $NPTS, 3, 4, 3);
&NCAR::aredam ($MAP, $XCNTR, $YCNTR4, $NPTS, 3, 5, 4);
&NCAR::aredam ($MAP, $XCNTR, $YCNTR5, $NPTS, 3, 6, 5);
#
# Fill water blue and contour lines according to area id.
#
&NCAR::arscam($MAP,$XWRK,$YWRK,$NWRK,$IAREA,$IGRP,$NGRPS,\&FILL);
#
# Write out area and group identifiers for each area, using red for
# geographic identifiers, and green for contour identifiers.
#
&NCAR::sflush();
&NCAR::gsplci(0);
for my $I ( 1 .. 12 ) {
  &NCAR::argtai($MAP, at( $X, $I-1 ), at( $Y, $I-1 ), $IAREA, $IGRP, $NGRPS, my $NAI, 0);
  for my $J ( 1 .. 2 ) {
    if( ( $I <= 6 ) || ( $I == 12 ) ) { &NCAR::gsplci( 3 ); }
    if( $I == 7 )  { &NCAR::gsplci( 0 ); }
    if( $I == 8 )  { &NCAR::gsplci( 3 ); }
    if( $I == 9 )  { &NCAR::gsplci( 6 ); }
    if( $I == 10 ) { &NCAR::gsplci( 0 ); }
    if( $I == 11 ) { &NCAR::gsplci( 3 ); }
    my $STRING = sprintf( ' A(%1d)=%1d G(%1d)=%1d', 
                          $J, at( $IAREA, $J-1 ), 
                          $J, at( $IGRP, $J-1 ) );
    if( at( $IGRP, $J-1 ) == 1 ) {
      &NCAR::plchhq (at( $X, $I-1 ), at( $Y, $I-1 ), $STRING, .01, 0., 0.);
    }
    if( at( $IGRP, $J-1 ) == 3 ) {
      &NCAR::plchhq (at( $X, $I-1 ), at( $Y, $I-1 )-.02, $STRING, .01, 0., 0.);
    }
  }
}
#
# Draw contours and perimeter in white
#
&NCAR::gsplci (6);
&NCAR::curve ($XCNTR,$YCNTR1,$NPTS);
&NCAR::curve ($XCNTR,$YCNTR2,$NPTS);
&NCAR::curve ($XCNTR,$YCNTR3,$NPTS);
&NCAR::curve ($XCNTR,$YCNTR4,$NPTS);
&NCAR::curve ($XCNTR,$YCNTR5,$NPTS);
&NCAR::curve ($XPERIM,$YPERIM,5);
      
&NCAR::frame;
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks;
#
# Write out amount of space needed for the area map
#
my $ISPACE = at( $MAP, 0 ) - at( $MAP, 5 ) + at( $MAP, 4 );
print STDERR "
Area Map Space Used: $ISPACE\n";


sub COLOR {
  my ( $IWKID ) = @_;      
#
# Define color table
#
# Background is black
#
  &NCAR::gscr($IWKID,0,0.,0.,0.);
#
# Red
#
  &NCAR::gscr($IWKID,1,1.,0.,0.);
#
# Green
#
  &NCAR::gscr($IWKID,2,0.,1.,0.);
#
# Yellow
#
  &NCAR::gscr($IWKID,3,1.,1.,0.);
#
# Blue
#
  &NCAR::gscr($IWKID,4,0.,0.,1.);
#
# Magenta
#
  &NCAR::gscr($IWKID,5,1.,0.,1.);
#
# White
#
  &NCAR::gscr($IWKID,6,1.,1.,1.);
#
# Aqua
#
  &NCAR::gscr($IWKID,7,0.,1.,1.);

}

sub FILL {
  my ($XWRK,$YWRK,$NWRK,$IAREA,$IGRP,$NGRPS) = @_;

  my $IDGEO=-1;
  my $IDCNTR=-1;
#
# Retrieve geographic and contour area identifier info
#
  for my $I ( 1 .. $NGRPS ) {
    if( at( $IGRP, $I-1 ) == 1 ) { $IDGEO = at( $IAREA, $I-1 ); }
    if( at( $IGRP, $I-1 ) == 3 ) { $IDCNTR = at( $IAREA, $I-1 ); }
  }
#
# If the contour segment is over water, then fill it in aquamarine
#
  if( $IDGEO == 1 ) {
    &NCAR::gsfaci(7);
    &NCAR::gfa($NWRK,$XWRK,$YWRK);
#
# If the contour band is over land, then fill it according to it's 
# area identifier info.
#
  } elsif( ( $IDGEO == 2 ) && ( $IDCNTR >= 1 ) ) {
    &NCAR::gsfaci($IDCNTR);
    &NCAR::gfa($NWRK,$XWRK,$YWRK);
  }

}
 
   
rename 'gmeta', 'ncgm/carfill.ncgm';
