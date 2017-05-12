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
# PURPOSE                To provide a simple demonstration of the
#                        CURVED line drawing techniques.
#
# USAGE                  CALL EXLINE (IWKID)
#
# ARGUMENTS
#
# ON INPUT               IWKID
#                          Workstation id
#
# LANGUAGE               FORTRAN
#
# PORTABILITY            FORTRAN 77
#
# NOTE                   The call to GOPWK will have to be modified
#                        when using a non-NCAR GKS package.  The third
#                        argument must be the workstation type for WISS.
#
#
my $XCOORD = zeroes float, 120;
my $YCOORD = zeroes float, 120;
my $XCOOR2 = zeroes float, 120;
my $YCOOR2 = zeroes float, 120;
my $XCOOR3 = zeroes float, 120;
my $YCOOR3 = zeroes float, 120;
#
# Establish the viewport and window.
#
&NCAR::set(.01,.99,0.01,.99,0.,1.,0.,1.,1);
#
# Turn buffering off
#
&NCAR::setusv('PB',2);
#
# Set up a color table
#
#     White background
&NCAR::gscr (1,0,1.,1.,1.);
#
# Black foreground
#
&NCAR::gscr (1,1,0.,0.,0.);
#
# Red
#
&NCAR::gscr (1,2,1.,0.,0.);
#
# Green
#
&NCAR::gscr (1,3,0.,1.,0.);
#
# Blue
#
&NCAR::gscr (1,4,0.,0.,1.);
#
# Set line color
#
&NCAR::gsplci(4);
#
# Set line width
#
&NCAR::gslwsc(2.);
#
# Draw a line of circles around the plotter frame
#
for my $I ( 0 .. 23 ) {
&GNCRCL($I/25.+.025, 0.+.025, .025, 25, $XCOORD, $YCOORD);
&NCAR::curved($XCOORD,$YCOORD,25);
&GNCRCL($I/25.+.025, 1.-.025, .025, 25, $XCOORD, $YCOORD);
&NCAR::curved($XCOORD,$YCOORD,25);
&GNCRCL(0.+.025,$I/25.+.025,.025, 25, $XCOORD, $YCOORD);
&NCAR::curved($XCOORD,$YCOORD,25);
&GNCRCL(1.-.025,$I/25.+.025,.025, 25, $XCOORD, $YCOORD);
&NCAR::curved($XCOORD,$YCOORD,25);
}
&GNCRCL(1.-.025,1.-.025,.025, 25, $XCOORD, $YCOORD);
&NCAR::curved($XCOORD,$YCOORD,25);
#
# Get the coordinates for a circle in the center of the frame
#
&GNCRCL(.5,.5,.333,30,$XCOOR2, $YCOOR2);
#
# Increase Line width
#
&NCAR::gslwsc(5.);
#
# Set the Line Color
#     
&NCAR::gsplci(2);
#
# Draw it
#
&NCAR::curved($XCOOR2,$YCOOR2,30);
#
# Using these coordinates, plot 30 smaller circles on the circle
#        Decrease Line Width
#
&NCAR::gslwsc(3.);
#
# Set the Line Color
#
&NCAR::gsplci(3);
for my $I ( 1 .. 30 ) {
&GNCRCL(at( $XCOOR2, $I-1 ),at( $YCOOR2, $I-1 ),.07,30,$XCOORD, $YCOORD);
&NCAR::curved($XCOORD,$YCOORD,30);
#
# Using these coordinates, plot 30 smaller circles on the circle
#
# Decrease Line Width
#
&NCAR::gslwsc(1.);
#
# Set the Line Color
#
&NCAR::gsplci(4);
for my $J ( 1 .. 30 ) {
&GNCRCL(at( $XCOORD, $J-1 ),at( $YCOORD, $J-1 ),.01,30,$XCOOR3, $YCOOR3);
&NCAR::curved($XCOOR3,$YCOOR3,30);
}
#
# Increase Line Width
#
&NCAR::gslwsc(3.);
#
# Set the Line Color
#
&NCAR::gsplci(3);
}
#
# Draw a label in the center
#
&NCAR::plchlq(.5,.7,'Circles',.03,0.,0.);
&NCAR::plchlq(.5,.6,'of',.03,0.,0.);
&NCAR::plchlq(.5,.5,'Circles',.03,0.,0.);
&NCAR::plchlq(.5,.4,'of',.03,0.,0.);
&NCAR::plchlq(.5,.3,'Circles',.03,0.,0.);


sub GNCRCL {
  my ($XCNTR, $YCNTR, $RAD, $NPTS, $XCOORD, $YCOORD) = @_;
#
# This function generates the coordinates for a circle with
# center at XCNTR, YCNTR, and a radius of RAD.  There are
# NPTS in the circle and the coordinates are returned in the
# arrays XCOORD and YCOORD.
#
# Compute number of radians per degree
#
  my $RADPDG = 2.*3.14159/360.;
#
# Initialize the angle
#
  my $ANGLE = 0.;
#
# Calculate the change in angle (360./number of points in circle)
#
  my $DELTA = 360./($NPTS-1);
#
# Convert to radians
#
  $DELTA = $DELTA * $RADPDG;
#
# Calculate each coordinate
#
  for my $I ( 1 .. $NPTS ) {
    set( $XCOORD, $I-1, $RAD * cos( $ANGLE ) + $XCNTR );
    set( $YCOORD, $I-1, $RAD * sin( $ANGLE ) + $YCNTR );
    $ANGLE = $ANGLE + $DELTA;
  }
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fdlcurvd.ncgm';
