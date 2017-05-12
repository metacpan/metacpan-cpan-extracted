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
      
#
#	$Id: cmpdrw.f,v 1.7 1999/04/07 21:25:09 kennison Exp $
#
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# Open GKS, Turn Clipping off
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Invoke demo driver
#
&CMPDRW($IWKID);
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();

sub CMPDRW {
  my ($IWKID) = @_;
#
# CMPDRW demonstrates using MAPDRW as a shortcut
#
  my $PLIM1 = float [  30., 0. ];
  my $PLIM2 = float [ -15., 0. ];
  my $PLIM3 = float [  60., 0. ];
  my $PLIM4 = float [  30., 0. ];
#
# Set up color table.
#
  &COLOR($IWKID);
#
# Draw Continental, political outlines in magenta
#
  &NCAR::mapstc ('OU - OUTLINE DATASET SELECTOR','PO');
  &NCAR::mapsti ('C5 - CONTINENTAL OUTLINE COLOR',5);
  &NCAR::mapsti ('C7 - COUNTRY OUTLINE COLOR',5);
#
# Draw grid lines and limb line in green
#
  &NCAR::mapsti ('C2 - GRID COLOR',2);
  &NCAR::mapsti ('C4 - LIMB COLOR',2);
#
# Draw labels and perimeter in white
#
  &NCAR::mapsti ('C1 - PERIMETER COLOR',1);
  &NCAR::mapsti ('C3 - LABEL COLOR',1);
#
# Set up satellite projection
#
  &NCAR::maproj ('SV',40.,-50.,0.);
  &NCAR::mapstr ('SA - SATELLITE DISTANCE',5.);
  &NCAR::mapset ('MA',$PLIM1,$PLIM2,$PLIM3,$PLIM4);
#
# Set grid spacing to 10 degrees, and anchor grid curve at 10 degree 
# intervals.
#
  &NCAR::mapstr ('GR - GRID SPACING',10.);
  &NCAR::mapstr ('GD - GRID DRAWING RESOLUTION',10.);
#
# Make sure Labels are turned on
#
  &NCAR::mapsti ('LA - LABEL FLAG',1);
#
# Label Size is given in NDCs by the formula NDC=LS/1024
#
  &NCAR::mapsti ('LS - LABEL SIZE',40);
#
# Draw dotted continental outlines, and make dots reasonably close
# together
#
  &NCAR::mapsti ('DO - DOTTED-OUTLINE SELECTOR',1);
  &NCAR::mapsti ('DD - DISTANCE BETWEEN DOTS',56);
#
# Initialize Maps, draw grid, labels perimeter, limb line, and outlines.
#
  &NCAR::mapdrw();
#
# Advance the frame.
#
  &NCAR::frame();
#
# Done.
#
}

sub COLOR {
  my ($IWKID) = @_;
#
# Background color
# The background is white here for better visibility on paper
#
  &NCAR::gscr($IWKID,0,1.,1.,1.);
#
# Foreground colors
#
  &NCAR::gscr($IWKID,1,.7,0.,0.);
  &NCAR::gscr($IWKID,2,0.,.7,0.);
  &NCAR::gscr($IWKID,3,.7,.4,0.);
  &NCAR::gscr($IWKID,4,.3,.3,.7);
  &NCAR::gscr($IWKID,5,.7,0.,.7);
  &NCAR::gscr($IWKID,6,0.,.7,.7);
  &NCAR::gscr($IWKID,7,0.,0.,0.);

}
   
rename 'gmeta', 'ncgm/cmpdrw.ncgm';
