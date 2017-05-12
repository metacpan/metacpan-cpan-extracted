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
# Set up a color table
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
# Set the line color
# 
&NCAR::gsplci(2);
#
# Set the plotter mapping space
#
&NCAR::set (0.,1.,0.,1.,0.,20., 0.,20.,1);
#
# Set the line width
#
&NCAR::gslwsc(4.);
#
#
# Draw a box
# 
&NCAR::line(2.,8.,2.,10.);
&NCAR::line(2.,10.,5.,10.);
&NCAR::line(5.,10.,5.,8.);
&NCAR::line(5.,8.,2.,8.);
#
# Add text
#
&NCAR::plchlq(3.5,9.,'Read I',15.,0.,0.);
#
# Draw a diamond
#
&NCAR::line(8.,9.,9.5,11.);
&NCAR::line(9.5,11.,11.,9.);
&NCAR::line(11.,9.,9.5,7.);
&NCAR::line(9.5,7.,8.,9.);
#
# Add text in Diamond
#
&NCAR::plchlq(9.5,9.,'Is I<3?',15.,0.,0.);
&NCAR::plchlq(10.,11.5,'yes',15.,0.,0.);
&NCAR::plchlq(9.9,6.5,'no',15.,0.,0.);
#
# Draw a box
# 
&NCAR::line(15.,13.,18.,13.);
&NCAR::line(18.,13.,18.,11.);
&NCAR::line(18.,11.,15.,11.);
&NCAR::line(15.,11.,15.,13.);
#
# Add text in box
#
&NCAR::plchlq(16.5,12.,'I = I+1',15.,0.,0.);
#
# Draw a box
# 
&NCAR::line(15.,7.,18.,7.);
&NCAR::line(18.,7.,18.,5.);
&NCAR::line(18.,5.,15.,5.);
&NCAR::line(15.,5.,15.,7.);
#
# Add text in box
#
&NCAR::plchlq(16.5,6.,'I = I-1',15.,0.,0.);
#
# Set the line width
#
&NCAR::gslwsc(2.);
#
# Set the line color
#
&NCAR::gsplci(4);
#
# Connect the objects
#
&NCAR::line(5.,9.,8.,9.);
&NCAR::line(9.5,11.,9.5,12.);
&NCAR::line(9.5,12.,15.,12.);
&NCAR::line(9.5,7.,9.5,6.);
&NCAR::line(9.5,6.,15.,6.);
#
# Label top of plot
#
&NCAR::plchhq(10.,15.,'Decision Flow Chart',25.,0.,0.);
#
# Draw a boundary around plotter frame
#
&NCAR::line(0.,0.,20.,0.);
&NCAR::line(20.,0.,20.,20.);
&NCAR::line(20.,20.,0.,20.);
&NCAR::line(0.,20.,0.,0.);


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fspline.ncgm';
