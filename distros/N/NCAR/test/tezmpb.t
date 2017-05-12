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
# $Id: tezmpb.f,v 1.1 1998/05/05 23:37:09 kennison Exp $
#
#
# Define error file, Fortran unit number, workstation type, and
# workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# Open GKS, open workstation of type 1, activate workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID,$LUNIT,$IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Invoke demo driver.
#
&TEZMPB (my $IERR,$IWKID);
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#



sub TEZMPB {
  my ($IERR,$IWKID) = @_;
#
# PURPOSE                To provide a simple demonstration of the use
#                        of EZMAPB.
#
# USAGE                  CALL TEZMPB (IERR,IWKID)
#
# ARGUMENTS
#
# ON OUTPUT              IERR
#
#                          an error parameter
#                          = 0, if the test is successful,
#                          = 1, otherwise
#
# I/O                    If the test is successful, the message
#
#                          EZMAPB TEST EXECUTED--SEE PLOTS TO CERTIFY
#
#                        is written on unit 6.
#
# PRECISION              Single.
#
# REQUIRED LIBRARY       EZMAP, EZMAPA, EZMAPB, AREAS, SPPS
# FILES
#
# REQUIRED GKS LEVEL     0A
#
# LANGUAGE               FORTRAN
#
# HISTORY                Written in May, 1998.
#
# ALGORITHM              TEZMPB draws a solid-color map of a portion
#                        of Europe.
#
# PORTABILITY            FORTRAN 77
#
#
# Define an array in which to construct the area map.
#
  my $IAMA = zeroes long, 100000;
#
# Dimension the arrays needed by ARSCAM and ARDRLN for x/y coordinates.
#
  my $XCRA = zeroes float, 2000;
  my $YCRA = zeroes float, 2000;
#
# Dimension the arrays needed by ARSCAM and ARDRLN for area and group
# identifiers.
#
  my $IAAI = zeroes long, 2;
  my $IAGI = zeroes long, 2;
#
# Declare the routine which will color the areas.
#
#       EXTERNAL COLRAM
#
# Declare the routine which will draw lines of latitude and longitude
# over water.
#
#       EXTERNAL COLRLN
#
  my $IOC = long [ 6,2,5,12,10,11,1,3,4,8,9,7,13,14 ];
#
  my @RGB = (
     [ 0.70 , 0.70 , 0.70 ],
     [ 0.75 , 0.50 , 1.00 ],
     [ 0.50 , 0.00 , 1.00 ],
     [ 0.00 , 0.00 , 1.00 ],
     [ 0.00 , 0.50 , 1.00 ],
     [ 0.00 , 1.00 , 1.00 ],
     [ 0.00 , 1.00 , 0.60 ],
     [ 0.00 , 1.00 , 0.00 ],
     [ 0.70 , 1.00 , 0.00 ],
     [ 1.00 , 1.00 , 0.00 ],
     [ 1.00 , 0.75 , 0.00 ],
     [ 1.00 , 0.38 , 0.38 ],
     [ 1.00 , 0.00 , 0.38 ],
     [ 1.00 , 0.00 , 0.00 ],
  );
#
# Force solid fill.
#
  &NCAR::gsfais (1);
#
# Define 15 different color indices.  The first 14 are spaced through
# the color spectrum and the final one is black.
#
  for my $J ( 1 .. 14 ) {
    my $I = at( $IOC, $J-1 );
    &NCAR::gscr ($IWKID,$J,@{ $RGB[$I-1] });
  }
#
# Set color index 15 to black.
#
  &NCAR::gscr ($IWKID,15,0.,0.,0.);
#
# Set up EZMAP.
#
  &NCAR::mapsti ('MV',1);
  &NCAR::mapstc ('OU','PO');
  &NCAR::maproj ('ME',0.,0.,0.);
  &NCAR::mapset ('CO',
                  float( [  30., 0 ] ),
		  float( [ -15., 0 ] ),
		  float( [  60., 0 ] ),
		  float( [  30., 0 ] )
		  );
#
# Make MPLNAM use 1 and 2 as the group identifiers.
#
  &NCAR::mapsti ('G1',1);
  &NCAR::mapsti ('G2',2);
#
# Use 5 vertical strips to reduce the number of points defining the
# sub-areas.
#
  &NCAR::mapsti ('VS',5);
#
# Initialize EZMAP.
#
  &NCAR::mapint();
#
# Initialize the area map.
#
  &NCAR::arinam ($IAMA,100000);
#
# Add edges to the area map.
#
  &NCAR::mplnam ('Earth..1',3,$IAMA);
#
# Pre-process the area map.
#
  &NCAR::arpram ($IAMA,0,0,0);
#
# Compute and print the amount of space used in the area map.
#
  my $ISU= at( $IAMA, 0 )-( at( $IAMA, 5 )- at( $IAMA, 4 ) - 1 );
  print STDERR "\n SPACE USED IN AREA MAP IS $ISU\n";
#
# Color the map.
#
  &NCAR::arscam ($IAMA,$XCRA,$YCRA,2000,$IAAI,$IAGI,2,\&COLRAM);
#
# Flush PLOTIT's buffers and set polyline color index to black.
#
  &NCAR::plotit (0,0,0);
  &NCAR::gsplci (15);
#
# In black, draw a perimeter and outline all the countries.
#
  &NCAR::mapsti ('LA',0);
  &NCAR::mapsti ('MV',1);
  &NCAR::maplbl();
  &NCAR::mplndr ('Earth..1',3);
#
# Draw lines of latitude and longitude over water.
#
  &NCAR::mapgrm ($IAMA,$XCRA,$YCRA,2000,$IAAI,$IAGI,2,\&COLRLN);
#
# Advance the frame.
#
  &NCAR::frame();
#
# Done.
#
  $IERR=0;
  print STDERR "\n  EZMAPB TEST EXECUTED--SEE PLOTS TO CERTIFY\n";
#
}



sub COLRAM {
  my ($XCRA,$YCRA,$NCRA,$IAAI,$IAGI,$NGPS) = @_;
#
# This is the routine that color-fills the areas defined by the area map.
# First, ITMP is set non-zero if and only if no area identifiers for the
# area are negative.
#
  my $ITMP=1;
#
  for my $I ( 1 .. $NGPS ) {
    if( at( $IAAI, $I-1 ) < 0 ) { $ITMP = 0; }
  }
#
# Then, if ITMP is non-zero (which says that we really do want to color-
# fill the area) ...
#
  if( $ITMP != 0 ) {
#
# set ITMP to equal to the value of the area identifier for the area
# relative to group 1 and ...
#
    $ITMP=0;
#
    for my $I ( 1 .. $NGPS ) {
      if( at( $IAGI, $I-1 ) == 1 ) { $ITMP = at( $IAAI, $I-1 ); }
    }
#
# if that area identifier is greater than zero, ...
#
    if( $ITMP > 0 ) {
#
# find the index of the suggested color for the area, set the fill area
# color index, and fill the area.
#
      &NCAR::gsfaci (&NCAR::mpisci($ITMP));
#
      &NCAR::gfa ($NCRA-1,$XCRA,$YCRA);
#
    }
#
  }
#
}


sub COLRLN {
  my ($XCRA,$YCRA,$NCRA,$IAAI,$IAGI,$NGPS) = @_;
#
# This is the routine that draws lines of latitude and longitude over
# water only.  First, ITMP is set non-zero if and only if no area
# identifiers for the area are negative.
#
  my $ITMP=1;
#
  for my $I ( 1 .. $NGPS ) {
    if( at( $IAAI, $I-1 ) < 0 ) { $ITMP = 0; }
  }
#
# Then, if ITMP is non-zero (which says that we really do want to draw
# things in the area) ...
#
  if( $ITMP != 0 ) {
#
# set ITMP to equal to the value of the area identifier for the area
# relative to group 1 (EZMAP lines) ...
#
    $ITMP=0;
#
    for my $I ( 1 .. $NGPS ) {
      if( at( $IAGI, $I-1 ) == 1 ) { $ITMP = at( $IAAI, $I-1 ); }
    }
#
# if the suggested color for the area implies that it is over water
# (the color index 1 is used only for water) ...
#
    if( &NCAR::mpisci( $ITMP ) == 1 ) {
#
# flush PLOTIT's buffers, set the polyline color index to black, and
# draw the line.
#
      &NCAR::plotit (0,0,0);
      &NCAR::gsplci (15);
#
      &NCAR::gpl ($NCRA,$XCRA,$YCRA);
#
    }
#
  }
#
}

rename 'gmeta', 'ncgm/tezmpb.ncgm';
