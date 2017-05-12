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
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# Open GKS.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# International outlines
#
&NCAR::mapstc ('OU - OUTLINE DATASET SELECTOR','PO');
#
# Satellite-view.
#
&NCAR::maproj ('SV',40.,10.,0.);
&NCAR::mapstr ('SA - SATELLITE DISTANCE',2.);
&NCAR::mapstr ('S1 - SATELLITE ANGLE 1',10.);
&NCAR::mapstr ('S2 - SATELLITE ANGLE 2',15.);
&NCAR::mapdrw();

&NCAR::frame();
#
# Deactivate and close the workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
      

   
rename 'gmeta', 'ncgm/cmpsat.ncgm';
