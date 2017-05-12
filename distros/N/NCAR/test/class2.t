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
#  Define error file, Fortran unit number, and workstation type,
#  and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
my $NPTS=200;
my $NCURVE=4;
my @YDRA = map { zeroes( float, $NPTS ) } ( 1 .. $NCURVE );
my $XDRA = zeroes float, $NPTS;
#
# Generate some data
#
for my $I ( 1 .. $NPTS ) {
  my $xdra = $I*0.1;
  set( $XDRA, $I-1, $xdra );
  for my $J ( 1 .. $NCURVE ) {
    set( $YDRA[$J-1], $I-1, sin($xdra+0.2*$J)*exp(-0.01*$xdra*$J**2) );
  }
}
#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Set up a color table
#
&DEFCLR($IWKID);
#
# Label the axes
#
&NCAR::plchhq(.5,.05,'Time (seconds)',.012,0.,0.);
&NCAR::plchhq(.025,.5,'Position (meters)',.012,90.,0.);
#
# Set the window for the range of the data and set the viewport to
# protect the axis labels
#
&NCAR::set(.1,.9,.1,.9,0.0,20.0,-1.4,1.4,1);
#
# Set up tick mark labels
#
&NCAR::labmod('(I2)','(F4.1)',0,0,8,8,0,0,0);
#
# Draw axes and their labels
#
&NCAR::gridal(10,2,15,2,1,1,5,0.0,0.0);
#
# Draw each curve with a different label
#
for my $I ( 1 .. $NCURVE ) {
  my $STRING = sprintf( '\'$$$$$$$$$$$$$$$$\'\'Curve\'\'%1d', $I );
  &NCAR::dashdc($STRING,1,1);
  &NCAR::gsplci($I+1);
  &NCAR::gstxci($I+1);
  &NCAR::curved($XDRA,$YDRA[$I-1],$NPTS);
}
#
# Close the frame
#
&NCAR::frame();
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks;

#
sub DEFCLR {
  my ($IWKID) = @_;
#
# Define a color table
#
# Background color is black
#
  &NCAR::gscr($IWKID, 0, 0.0, 0.0, 0.0);
#
# Default foreground color is white
#
  &NCAR::gscr($IWKID, 1, 1.0, 1.0, 1.0);
#
# Red
#
  &NCAR::gscr($IWKID, 2, 1.0, 0.0, 0.0);
#
# Green
#
  &NCAR::gscr($IWKID, 3, 0.0, 1.0, 0.0);
#
# Blue 
#
  &NCAR::gscr($IWKID, 4, 0.4, 0.7, 0.9);
#
# Magenta
#
  &NCAR::gscr($IWKID, 5, 0.7, 0.4, 0.7);
#
# Orange
#
  &NCAR::gscr($IWKID, 6, 0.9, 0.7, 0.4);
#
# Teal
#
  &NCAR::gscr($IWKID, 7, 0.4, 0.9, 0.7);
  
}


rename 'gmeta', 'ncgm/class2.ncgm';
