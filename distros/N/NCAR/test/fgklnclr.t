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
#                        how to change line color..
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
#  Data for the graphical objects.
#
my $TWOPI = 6.283185;
my ( $X0P, $Y0P, $RP, $NPTP ) = ( 0.500, 0.5, 0.40 ,  16 );
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
#     White background
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
#  Create a polygonal fan 
#
my $DTHETA = $TWOPI/$NPTP;
for my $I ( 1 .. 16 ) {
  my $ANG = $DTHETA*$I + .19625;
  my $XC = $RP*cos($ANG);
  my $YC = $RP*sin($ANG);
#
# Set the line color
# 
&NCAR::gsplci (($I % 4)+1);
#
# Set line width 
# 
&NCAR::gslwsc(6.) ;
#
# Draw a line
#
&NCAR::lined($X0P,$Y0P,$X0P+$XC,$Y0P+$YC);
}
      
&NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
#
#     Set the line color to black
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
&NCAR::plchlq(0.5,0.91,'Changing Line Color',25.,0.,0.);


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fglnclr.ncgm';
