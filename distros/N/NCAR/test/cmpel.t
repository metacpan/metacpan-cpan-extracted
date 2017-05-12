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
#	$Id: cmpel.f,v 1.4 1995/06/14 14:07:02 haley Exp $
#
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# Open GKS and turn off clipping.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
&NCAR::gsclip (0);
#
# Call the routine which does all the work
#
&CMPEL();
#
# Close GKS, and end program
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();


sub CMPEL {
#
# Satellite-view.
#
# Do this plot in white with Softfill over the water and no lat/lon
# lines
#
  &NCAR::maproj ('SV',40.,10.,0.);
  &NCAR::mapstr ('SA - SATELLITE DISTANCE',5.);
  &NCAR::mapstc ('OU - OUTLINE DATASET SELECTOR','PO');
  &NCAR::mapsti ('PE - PERIMETER FLAG', 0);
  &NCAR::mapsti ('EL - ELLIPTICAL-PERIMETER SELECTOR', 1);
  &NCAR::mapint();
  &NCAR::maplbl();
  &NCAR::maplot();
  &NCAR::frame();

}

rename 'gmeta', 'ncgm/cmpel.ncgm';
