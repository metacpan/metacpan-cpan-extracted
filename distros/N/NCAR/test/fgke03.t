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
my ( $IERRF, $LUNIT, $IWKID ) = ( 6, 2, 1 );
#
#  Illustrate creating multiple metafiles in the same job.
#
#
#  Open GKS.
#
&NCAR::gopks ($IERRF, my $ISZDM);
my $CDUM = ' ' x 80;
#
#  Open and activate a metafile with the name META01.
#
my $FNAME;
$FNAME = sprintf( '%-80s', 'META01' );
&NCAR::gesc(-1391,1,[ $FNAME ],1,1,[ $CDUM ]);
&NCAR::gopwk ($IWKID, $LUNIT, 1);
&NCAR::gacwk ($IWKID);
#
#  Draw a single polymarker in the center of the picture.
#
&NCAR::gpm(1,.5,.5);
&NCAR::frame;
#
#  Deactivate and close the META01 metafile.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
#
#  Open and activate META02.
#
$FNAME = sprintf( '%-80s', 'META02' );
&NCAR::gesc(-1391,1,[ $FNAME ],1,1,[ $CDUM ]);
&NCAR::gopwk ($IWKID, $LUNIT, 1);
&NCAR::gacwk ($IWKID);
#
#  Draw a single polymarker in the upper half of the picture.
#
&NCAR::gpm(1,.5,.75);
&NCAR::frame;
#
#  Deactivate and close the META02 metafile.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
#
#  Close GKS.
#
&NCAR::gclks;
#

rename 'META01', 'ncgm/fgke03.META01.ncgm';
rename 'META02', 'ncgm/fgke03.META02.ncgm';
