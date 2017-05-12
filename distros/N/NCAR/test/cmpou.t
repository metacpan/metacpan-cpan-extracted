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
#   $Id: cmpou.f,v 1.4 1995/06/14 14:07:13 haley Exp $
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
&CMPOU();
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();


sub CMPOU {
  my $PLIM1 = float [  30., 0. ];
  my $PLIM2 = float [ -15., 0. ];
  my $PLIM3 = float [  60., 0. ];
  my $PLIM4 = float [  30., 0. ];
#
# CMPOU demonstrates political boundaries in the Maps utility.
#
# Set up Maps.
#
  &NCAR::mapstc ('OU - OUTLINE DATASET SELECTOR','PO');
  &NCAR::maproj ('ME',0.,0.,0.);
  &NCAR::mapset ('CO',$PLIM1,$PLIM2,$PLIM3,$PLIM4);
#
# Initialize Maps.
#
  &NCAR::mapint();
#
# Draw a perimeter and outline all the countries.
#
  &NCAR::mapsti('LA - LABEL FLAG',0);
  &NCAR::maplbl();
  &NCAR::maplot();
#
# Advance the frame.
#
  &NCAR::frame();
#
# Done.
#
}
   
rename 'gmeta', 'ncgm/cmpou.ncgm';
