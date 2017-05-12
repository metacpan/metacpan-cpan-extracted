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
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
# PURPOSE                To provide a simple demonstration of the
#                        PLCHLQ text drawing techniques.
#
# USAGE                  CALL EXPCLQ (1)
#
# ARGUMENTS
#
# ON INPUT               1
#                          A workstation id
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
my $XCOOR2 = zeroes float, 500;
my $YCOOR2 = zeroes float, 500;
#
# Turn buffering off
#
&NCAR::setusv('PB',2);
#
# Set up a color table
#
#  White background
#
&NCAR::gscr (1,0,1.,1.,1.);
#
#  Black foreground
#
&NCAR::gscr (1,1,0.,0.,0.);
#
#  Red
#
&NCAR::gscr (1,2,1.,0.,0.);
#
#  Green
#
&NCAR::gscr (1,3,0.,1.,0.);
#
#  Blue
#
&NCAR::gscr (1,4,0.,0.,1.);
#
# Establish the viewport and window.
#
&NCAR::set(.0,1.,0.,1.,0.,1.,0.,1.,1);
#
# Get the coordinates for a Spiral in the center of the frame
#
&GNSPRL(.5,.5,.45,500,4,$XCOOR2, $YCOOR2);
#
#  Set line width
#
&NCAR::gslwsc(3.);
#
#  Set line color
#
&NCAR::gsplci(2);
#
#  Draw the spiral
#
&NCAR::curved($XCOOR2,$YCOOR2,500);
#
# Draw labels
#  Set text color
#
&NCAR::gstxci(4);
#
# Set the font
#
&NCAR::gstxfp(-13,2);
#
# Plot the strings
#
&NCAR::plchlq(.41,.58,'Use',.04,55.,0.);
&NCAR::plchlq(.58,.62,'PLCHLQ',.03,-25.,0.);
#
# Set the font
#
&NCAR::gstxfp(-6,2);
#
# Plot the strings
#
&NCAR::plchlq(.66,.47,'to',.04,-90.,0.);
&NCAR::plchlq(.57,.33,'access',.05,-145.,0.);
#
# Set the font
#
&NCAR::gstxfp(-12,2);
#
# Plot the strings
#
&NCAR::plchlq(.39,.32,'the',.05,150.,0.);
&NCAR::plchlq(.28,.47,'GKS',.05,110.,0.);
#
# Set the font
#
&NCAR::gstxfp(-16,2);
#
# Plot the strings
#
&NCAR::plchlq(.34,.67,'fonts',.05,45.,0.);
&NCAR::plchlq(.525,.75,'and',.05,0.,0.);
#
# Set the font
#
&NCAR::gstxfp(-7,2);
#
#  Plot the strings
#
&NCAR::plchlq(.74,.59,'position',.05,-65.,0.);
&NCAR::plchlq(.73,.31,'text',.05,-130.,0.);
#
# Set the font
#
&NCAR::gstxfp(1,2);
#
#  Plot the strings
#
&NCAR::plchlq(.57,.20,'at',.05,-165.,0.);
&NCAR::plchlq(.40,.20,'any',.05,165.,0.);
#
# Set the font
#
&NCAR::gstxfp(-9,2);
#
# Plot the string
#
&NCAR::plchlq(.23,.32,'angle.',.05,130.,0.);

sub GNSPRL {
  my ($XCNTR,$YCNTR,$IRADUS,$NPTS,$LOOPS,$XCOORD,$YCOORD) = @_;
#
# This function generates the coordinates for a spiral with
# center at XCNTR, YCNTR, and an initial radius of IRADUS. The spiral
# will turn on itself LOOPS times.  There are
# NPTS in the Spiral and the coordinates are returned in the
# arrays XCOORD and YCOORD.
#
  my $RADIUS = $IRADUS;
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
  my $DELTA = ($LOOPS) * 360./(($NPTS-1));
#
# Convert to radians
#
  $DELTA = $DELTA * $RADPDG;
#
# Calculate the change in radius
#
  my $DRAD = $RADIUS/(($NPTS - 1));
#
# Calculate each coordinate
#
  for my $I ( 1 .. $NPTS ) {
    set( $XCOORD, $I-1, $RADIUS * (cos($ANGLE)) + $XCNTR );
    set( $YCOORD, $I-1, $RADIUS * (sin($ANGLE)) + $YCNTR );
#
# Increase the angle
#
    $ANGLE = $ANGLE + $DELTA;
#
# Reduce the radius
#
    $RADIUS = $RADIUS - $DRAD;
  }
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fpcloqu.ncgm';
