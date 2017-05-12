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
#                        GKS line drawing techniques.
#
# USAGE                  CALL GPLXPL (IWKID)
#
# Coordinate arrays
#
my $XCD = zeroes float, 1500;
my $YCD = zeroes float, 1500;
#
# Declare the constant for converting from degrees to radians.
#
my $DTR = .017453292519943;
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
# Draw a world map
#
# Position the map on the plotter frame
#
&NCAR::mappos(.01,.99,.01,.99);
#
# Define a map projection
#
&NCAR::maproj('CE',0., -150., 0.);
#
# Choose map limits 
#
&NCAR::mapset('CO', 
              float( [  60., 0 ] ), 
	      float( [  30., 0 ] ),
	      float( [ -60., 0 ] ), 
	      float( [ -30., 0 ] )
	      );
#
# Choose continental outlines
#
&NCAR::mapstc ('OU', 'CO');
#
# Turn off grid lines
#
&NCAR::mapstr ('GR',0.)      ;
#
# Draw it
#
&NCAR::mapdrw;
#
# Create a spiral curve
#
#  Set the line color to red
#
&NCAR::gsplci (2);
for my $ING ( 1 ..1500 ) {
  my $RAD=($ING)/1000.;
  my $ANG=$DTR*($ING-1);
  set( $XCD, $ING-1, .25+.5*$RAD*cos($ANG) );
  set( $YCD, $ING-1, .25+.5*$RAD*sin($ANG) );
}
#
# Draw 3 spirals on the map over areas of high hurricane
# probability.  Draw 2 additional spirals at the bottom
# of the plot to use as a key.  Dashed spirals indicate
# relatively low areas of hurricane probability, while solid
# spirals indicate higher probability.
#
# Set the line type to solid (the default)
#
&NCAR::gsln(1);
#
# Set the position of the spiral
#
&NCAR::set (.24,.37,.48,.61,-1.,1.,-1.,1.,1);
#
# Draw the line
#
&NCAR::gpl(1500, $XCD, $YCD);
#
# Set the position of the spiral
#
&NCAR::set (.03,.10,.43,.50,-1.,1.,-1.,1.,1);
#
#  Draw the line
#
&NCAR::gpl(1500, $XCD, $YCD);
#
# Set the position of the spiral
#
&NCAR::set (.62,.75,.47,.60,-1.,1.,-1.,1.,1);
#
# Draw the line
#
&NCAR::gpl(1500, $XCD, $YCD);
#
# Set the position of the spiral
#
&NCAR::set (.25,.38,.10,.23,-1.,1.,-1.,1.,1);
#
# Draw the line
#
&NCAR::gpl(1500, $XCD, $YCD);
#
# Set the position of the spiral
#
&NCAR::set (.65,.72,.10,.17,-1.,1.,-1.,1.,1);
#
# Draw the line
#
&NCAR::gpl(1500, $XCD, $YCD);
#
# Reset the plot window
#
&NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
#
# Set the line color to black
#
&NCAR::gsplci (1);
#
#  Create a background perimeter 
#
&NCAR::frstpt( 0.0, 0.0);
&NCAR::vector( 1.0, 0.0);
&NCAR::vector( 1.0, 1.0);
&NCAR::vector( 0.0, 1.0);
&NCAR::vector( 0.0, 0.0);
#
#  Label the plot
#
&NCAR::plchlq(0.5,0.80,'Areas of High Hurricane Probability',25.,0.,0.);

&NCAR::plchlq(0.5,0.25,'Average number of tropical cyclones per 5 degree square per year',15.,0.,0.);

&NCAR::plchlq(0.33,0.10,'> 3',15.,0.,0.);

&NCAR::plchlq(0.70,0.10,'2<n<3',15.,0.,0.);


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fgkgpl.ncgm';
