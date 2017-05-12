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
# PURPOSE                To provide a simple demonstration of 
#                        how to set line dash patterns. 
#
# USAGE                  CALL LINEEX (IWKID)
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
my $STR;
my $XCOORD = zeroes float, 360;
my $YCOORD = zeroes float, 360;
#
#  Data for the graphical objects.
#
my $TWOPI = 6.283185;
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
# White background
#
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
# Create and Plot 2 Sine Curves
#
# Set the dash pattern
#
$STR = '$\'$\'Line\'drawn\'with\'VECTD$\'$\'$\'$\'';
&NCAR::dashdc($STR,15,20);
#
# Move plotter pen
#
&NCAR::frstd(0.,.60);
for my $I ( 1 .. 360 ) {
  my $Y = (sin(($I)*($TWOPI/360.)) * .25) + .60;
  &NCAR::vectd(($I)/360.,$Y);
}
#
# Set the Dash pattern
#
$STR = '$$$$$$Line\'drawn\'with\'CURVED$$$$$$$$$$$$';
&NCAR::dashdc($STR,15,20);
&NCAR::gslwsc(3.);
for my $I ( 1 .. 360 ) {
  set( $XCOORD, $I-1, $I/360. );
  set( $YCOORD, $I-1, (sin($I*($TWOPI/360.)) * .25) + .45 );
}
#
# Draw the second curve
#
&NCAR::curved($XCOORD, $YCOORD, 360);
#
# Draw a straight line
#
&NCAR::gslwsc(4.);
#
# 1111100110011111 binary  = 63903 decimal
#
&NCAR::dashdb(63903);
&NCAR::lined(0.1,.15, .9,.15);
#
# Label the line
#
&NCAR::plchlq(0.5,0.10,'Line drawn with LINED',20.,0.,0.);
#
#  Create a background perimeter 
#
&NCAR::gsplci(1);
&NCAR::frstpt( 0.0, 0.0);
&NCAR::vector( 1.0, 0.0);
&NCAR::vector( 1.0, 1.0);
&NCAR::vector( 0.0, 1.0);
&NCAR::vector( 0.0, 0.0);
#
#  Label the plot
#
&NCAR::plchlq(0.7,0.90,'Setting Dash Patterns',25.,0.,0.);
&NCAR::plchlq(0.7,0.81,'with DASHDB and DASHDC',25.,0.,0.);
&NCAR::frame;
#


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fdldashd.ncgm';
