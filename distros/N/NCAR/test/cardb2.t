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
my ( $LMAP, $NMAP, $NPTS, $NCNTR ) = ( 150000, 43, 50, 5 );
      
my $MAP = zeroes long, $LMAP;
my $XCNTR  = zeroes float, $NPTS;
my $YCNTR  = zeroes float, $NPTS;
my $YCNTR1 = zeroes float, $NPTS;
my $YCNTR2 = zeroes float, $NPTS;
my $YCNTR3 = zeroes float, $NPTS;
my $YCNTR4 = zeroes float, $NPTS;
my $YCNTR5 = zeroes float, $NPTS;
      
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
my $XPERIM = float [ 0.0, 1.0, 1.0, 0.0, 0.0 ];
my $YPERIM = float [ 0.0, 0.0, 1.0, 1.0, 0.0 ];
my $X = float [ 
            .10, .22, .25, .25, .25, .50,
            .30, .47, .50, .77, .75, .68 ];
my $Y = float [
            .98, .70, .55, .38, .18, .18,
            .90, .85, .70, .35, .18, .05 ];
      
set( $XCNTR , 1-1, 0.0   );
set( $YCNTR1, 1-1, 0.27  );
set( $YCNTR2, 1-1, 0.22  );
set( $YCNTR3, 1-1, 0.60  );
set( $YCNTR4, 1-1, 0.80  );
set( $YCNTR5, 1-1, 0.95  );
for my $J ( 2 .. $NPTS ) {
  my $DIST = $J/$NPTS;
  set( $XCNTR , $J-1, $DIST );
  set( $YCNTR1, $J-1, .1*cos((4*3.14*$DIST))+.15 );
  set( $YCNTR2, $J-1, .1*sin((4*3.14*$DIST-.78))+.30 );
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
#
# Outline continents in red
#
&NCAR::curve ($XGEO,$YGEO,$NMAP);
#
# Outline contours and perimeter in green
#
&NCAR::curve ($XCNTR,$YCNTR1,$NPTS);
&NCAR::curve ($XCNTR,$YCNTR2,$NPTS);
&NCAR::curve ($XCNTR,$YCNTR3,$NPTS);
&NCAR::curve ($XCNTR,$YCNTR4,$NPTS);
&NCAR::curve ($XCNTR,$YCNTR5,$NPTS);
&NCAR::curve ($XPERIM,$YPERIM,5);
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
# Run debugging subroutine on group 3
#
&NCAR::ardbpa ($MAP, 3, 'Crossing Contours');
&NCAR::ardbpa ($MAP, 1, 'Crossing Contours');
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
   
rename 'gmeta', 'ncgm/cardb2.ncgm';
