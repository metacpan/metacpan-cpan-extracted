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
# This program demonstrates how to use the SPPS CURVE routine and
# the GKS GPL routine.  Both routine are given the same set of
# coordinates to draw, however, because of the SET call the x axis
# is reversed.  GPL ignores this, and CURVE obeys it.
#
#
# Coordinates for plot key
#
my @X2 = (.2, .3);
my @Y2 = (.1, .1);
my @X3 = (.7, .8);
my @Y3 = (.1, .1);
#
# Coordinates for line (used by both GPL and CURVE)
#
my $XCOORD = float [ 1.,2.,3.,5.,7.,9.,13.,16.,19.,23. ];
my $YCOORD = float [ 1.,3.,5.,6.,7.,10.,13.,16.,14.,17.];
#
# Map the plotter frame to user coordinates.  Notice that
# we have reversed the X axis here.
#
&NCAR::set (0.,1., 0., 1., 25., 0., 0., 20., 1);
#
# Set the line type to dashed.
#
&NCAR::gsln(2);
#
# Draw the line with GPL. It will ignore the axis reversal.
#
&NCAR::gpl(10,$XCOORD,$YCOORD);
#
# Set the line type to solid
#
&NCAR::gsln(1);
#
# Draw the line with CURVE.  It will observe the axis reversal
#
&NCAR::curve($XCOORD,$YCOORD,10);
#
# Reset the plotter to user coordinate mapping to make it easier
# to plot the text and key.  (Axis reversal is turned off)
#
&NCAR::set (0.,1., 0., 1., 0., 1., 0., 1., 1);
#
# Draw the text
#
&NCAR::plchlq(.25, .15, 'GKS GPL Routine', 15., 0., 0.);
#
# Set line type to dashed.
#
&NCAR::gsln(2);
#
# Draw a dashed line under the previous text
#
&NCAR::gpl(2,float( \@X2 ),float( \@Y2));
#
# Draw more text
#
&NCAR::plchlq(.75, .15, 'SPPS CURVE Routine', 15., 0., 0.);
#
# Set line type to solid.
#
&NCAR::gsln(1);
#
# Draw a solid line under the previous text
#
&NCAR::gpl(2,float( \@X3 ),float( \@Y3 ));
#
# Draw a main title
#
&NCAR::plchlq(.5, .9, 'Drawing lines with GPL and CURVE', 20.,0., 0.);
#
# Draw a border around the plot
#
&NCAR::line(0.,0.,1.,0.);
&NCAR::line(1.,0.,1.,1.);
&NCAR::line(1.,1.,0.,1.);
&NCAR::line(0.,1.,0.,0.);
#
# Advance the frame 
#

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fspcurve.ncgm';
