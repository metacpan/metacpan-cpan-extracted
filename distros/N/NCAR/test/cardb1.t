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
my ( $NPTS, $MAPSIZ, $IDSIZE, $MCS ) = ( 101, 5000, 1, 1000 );
my $X1 = zeroes float, $NPTS;
my $Y1 = zeroes float, $NPTS;
my $X2 = zeroes float, $NPTS;
my $Y2 = zeroes float, $NPTS;
my $X3 = zeroes float, $NPTS;
my $Y3 = zeroes float, $NPTS;
my $XC = zeroes float, $MCS;
my $YC = zeroes float, $MCS;
my $MAP = zeroes long, $MAPSIZ;
my $AREAID = zeroes long, $IDSIZE; 
my $GRPID = zeroes long, $IDSIZE; 
      
#     EXTERNAL FILL
      
my $D2R = .017453292519943;
#
# draw circles of radius .9 and .85 centered on the origin
#
for my $I ( 1 .. $NPTS ) {
  my $ANGLE = $D2R*3.6*($I-1);
  my $X = cos($ANGLE);
  my $Y = sin($ANGLE);
  set( $X1, $I-1, 0.90*$X );
  set( $Y1, $I-1, 0.90*$Y );
  set( $X2, $I-1, 0.85*$X );
  set( $Y2, $I-1, 0.85*$Y );
}
#
# get data to draw a pentagram inside inner circle.
#
my $NVERT = 6;
&STAR($X3,$Y3,$NVERT,$D2R);
#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Define color table
#
&COLOR($IWKID);
#
# Define window from -1. to 1.
#
&NCAR::set(0.,1.,0.,1.,-1.,1.,-1.,1.,1);
&NCAR::gschh (.2);
# 
# Initialize Areas
#
&NCAR::arinam($MAP, $MAPSIZ);
&NCAR::arseti('DB - DEBUG PLOTS',1);
#
# Add edges to area map
#
&NCAR::aredam($MAP, $X1, $Y1, $NPTS, 1, 1, 0);
&NCAR::aredam($MAP, $X2, $Y2, $NPTS, 1, 2, 1);
&NCAR::aredam($MAP, $X3, $Y3, $NVERT, 1, 3, 2);
#
# Fill regions according to instructions
#
&NCAR::arscam($MAP, $XC, $YC, $MCS, $AREAID, $GRPID, $IDSIZE, \&FILL);
#
# Advance frame
#
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
  &NCAR::gscr($IWKID,0,0.,0.,0.);
  &NCAR::gscr($IWKID,1,1.,0.,0.);
  &NCAR::gscr($IWKID,2,0.,1.,0.);
  &NCAR::gscr($IWKID,3,1.,1.,0.);
  &NCAR::gscr($IWKID,4,0.,0.,1.);
  &NCAR::gscr($IWKID,5,1.,0.,1.);
  &NCAR::gscr($IWKID,6,0.,1.,1.);
  &NCAR::gscr($IWKID,7,1.,1.,1.);
      
}

sub FILL {
  my ($XC, $YC, $PTS, $AREAID, $GRPID, $IDSIZE) = @_;
#
# In this case, we have only one group, so we know that
# AREAID(IDSIZE) is a unique area identifier.
#
# If the area is the ring between circles solid fill red
#
  if( at( $AREAID, $IDSIZE-1 ) == 1 ) {
    &NCAR::gsfais(1);
    &NCAR::gsfaci(1);
    &NCAR::gfa($PTS,$XC,$YC);
#
# If the area is between the ring and the star, hatch fill in yellow
#
  } elsif( at( $AREAID, $IDSIZE-1 ) == 2 ) {
    &NCAR::gsfais(3);
    &NCAR::gsfasi(6);
    &NCAR::gsfaci(3);
    &NCAR::gfa($PTS,$XC,$YC);
#
# If the area is inside the star, solid fill in aqua
#
  } elsif( at( $AREAID, $IDSIZE-1 ) == 3 ) {
    &NCAR::gsfais(1);
    &NCAR::gsfaci(6);
    &NCAR::gfa($PTS,$XC,$YC);
  }

}

sub STAR {
  my ($X3,$Y3,$NVERT,$D2R) = @_;    
  my $DIST = (1.0 - 0.835*cos($D2R*36.));
      
  set( $X3, 1-1, 0.85*cos($D2R* 18.) );
  set( $Y3, 1-1, 0.85*sin($D2R* 18.) );
  set( $X3, 4-1, 0.00 );
  set( $Y3, 4-1, 0.85 );
  set( $X3, 2-1, 0.85*cos($D2R*162.) );
  set( $Y3, 2-1, 0.85*sin($D2R*162.) );
  set( $X3, 5-1, 0.85*cos($D2R*234.) );
  set( $Y3, 5-1, 0.85*sin($D2R*234.) );
  set( $X3, 3-1, 0.85*cos($D2R*306.) );
  set( $Y3, 3-1, 0.85*sin($D2R*306.) );
  set( $X3, 6-1, at( $X3, 0 ) );
  set( $Y3, 6-1, at( $Y3, 0 ) );

}

   
rename 'gmeta', 'ncgm/cardb1.ncgm';
