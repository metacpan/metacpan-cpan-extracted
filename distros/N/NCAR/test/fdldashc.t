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
#                        different line drawing techniques.
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
# HISTORY                Written  by members of the
#                        Scientific Computing Division of NCAR,
#                        Boulder Colorado
#
# PORTABILITY            FORTRAN 77
#
# NOTE                   The call to GOPWK will have to be modified
#                        when using a non-NCAR GKS package.  The third
#                        argument must be the workstation type for WISS.
#
#
#
#  Data for the graphical objects.
#
my $TWOPI = 6.283185;
my ( $X0P, $Y0P, $RP, $NPTP ) = ( 0.500, 0.5, 0.45 ,  16 );
#
# Declare the constant for converting from degrees to radians.
#     
my $DTR = .017453292519943;
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
#  Create a polygonal fan 
#
my $DTHETA = $TWOPI/$NPTP;
for my $I ( 1 .. 6 ) {
  my $ANG = $DTHETA*$I + .19625;
  my $XC = $RP*cos($ANG);
  my $YC = $RP*sin($ANG);
#
# Set the line color
# 
  &NCAR::gsplci ( ( $I % 4) + 1 );
#
# Set line width 
# 
  &NCAR::gslwsc(2.) ;
  if( $I == 1 ) {
#
#  Solid Line (the default)
#
    my $STR = '$$$$Solid$$$$$$$$$$$$$$$$$$$$$$$$$$$$$';
    &NCAR::dashdc($STR,20,20);
    &NCAR::gsln(1);
    &NCAR::lined($X0P,$Y0P,$X0P+$XC,$Y0P+$YC);
  } elsif( $I == 2 ) {
#
# Dashed line
#
    my $STR = '$$$$Dashed$$$$$$$$$$$$$$$$$$$$$$$$$$$$$';
    &NCAR::dashdc($STR,20,20);
    &NCAR::gsln(2);
    &NCAR::lined($X0P,$Y0P,$X0P+$XC,$Y0P+$YC);
  } elsif( $I == 3 ) {
#
# Dotted line
#
    my $STR = '$$$$Dotted$$$$$$$$$$$$$$$$$$$$$$$$$$$$$';
    &NCAR::dashdc($STR,20,20);
    &NCAR::gsln(3);
    &NCAR::lined($X0P,$Y0P,$X0P+$XC,$Y0P+$YC);
  } elsif( $I == 4 ) {
#
# Dashed dotted line
#
    my $STR = '$$$$Dotted\'Dashed$$$$$$$$$$$$$$$$$$$$$$$$$$$$$';
    &NCAR::dashdc($STR,20,20);
    &NCAR::gsln(4);
    &NCAR::lined($X0P,$Y0P,$X0P+$XC,$Y0P+$YC);
  } elsif( $I == 5 ) {
#
# Don't do anything different here
# Color is changed at beginning of loop
#
    my $STR = '$$$$Color\'Any$$$$$$$$$$$$$$$$$$$$$$$$$$$$$';
    &NCAR::dashdc($STR,20,20);
    &NCAR::lined($X0P,$Y0P,$X0P+$XC,$Y0P+$YC);
  } elsif( $I == 6 ) {
#
# Increase the line width 
#
    my $STR = '$$$$Width\'Any$$$$$$$$$$$$$$$$$$$$$$$$$$$$$';
    &NCAR::dashdc($STR,20,20);
    &NCAR::gslwsc(10.) ;
    &NCAR::lined($X0P,$Y0P,$X0P+$XC,$Y0P+$YC);
  } elsif( $I == 7 ) {
  } elsif( $I == 8 ) {
  }
#
# Reset the line type to a thin black solid line
#
  &NCAR::gsln(1);
  &NCAR::gslwsc(2.) ;
  &NCAR::gsplci (1);
}
#
# Create and Plot 2 Sine Curves
#
# Set line width
#
&NCAR::gslwsc(4.) ;
#
# Set the dash pattern
#
my $STR = '$\'$Draw\'Any\'Curve$\'$\'$\'$\'$\'$\'$\'';
&NCAR::dashdc($STR,15,20);
#
# Move plotter pen
#
&NCAR::frstd(0.,.25);
#
# Compute the curve coordinates
#
for my $I ( 1 ..360 ) {
  my $Y = (sin($I*($TWOPI/360.)) * .25) + .25;
  &NCAR::vectd($I/360.,$Y);
}
#
# Set line width
#
&NCAR::gslwsc(2.) ;
#
#  Set the dash pattern
#
$STR = '$\'$$\'$$$\'$$$$ Any\'Pattern';
&NCAR::dashdc($STR,20,20);
#
# Set the line color to green
#
&NCAR::gsplci (3);
#
# Move plotter pen
#
&NCAR::frstd(0.,.125);
#
# Compute the curve coordinates
#
for my $I ( 1 .. 360 ) {
  my $Y = (sin(($I)*($TWOPI/360.)) * .125) + .125;
  &NCAR::vectd(($I)/720.,$Y);
}
#
# Create and plot a spiral curve
#
&NCAR::set (.4,.9,.0,.55,-1.,1.,-1.,1.,1);
$STR = '$$$$$$$$$$$$$$$$$$$$$$$$$$Any\'Shape';
&NCAR::dashdc($STR,80,20);
#
# Move plotter pen
#
my $RAD=.001;
my $XCD=.25+.5*$RAD*cos(0.);
my $YCD=.25+.5*$RAD*sin(0.);
&NCAR::frstd($XCD,$YCD);
#
# Set the line color to red
#
&NCAR::gsplci (2);
for my $ING ( 1 .. 1500 ) {
  $RAD=($ING)/1000.;
  my $ANG=$DTR*($ING-1);
  $XCD=.25+.5*$RAD*cos($ANG);
  $YCD=.25+.5*$RAD*sin($ANG);
  &NCAR::vectd($XCD, $YCD);
}
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
#     CALL PLCHLQ(0.5,0.91,\',25.,0.,0.)
&NCAR::frame;


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fdldashc.ncgm';
