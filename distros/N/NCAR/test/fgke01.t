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

my $IERRF=6;
my $LUNIT=2;
my $IWKID=1;
my $IWKID2=2;
#
#  Simple example illustrating opening GKS, opening and activating
#  a CGM workstation and an X11 workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
#
#  Specify text alignment of (center, half) and set character height.
#
&NCAR::gstxal(2,3);
&NCAR::gschh(.05);
#
#  Open a CGM workstation with workstation ID of IWKID.
#
&NCAR::gopwk ($IWKID, $LUNIT, 1);
#
#  Open an X11 workstation with workstation ID of IWKID2.
#
&NCAR::gopwk($IWKID2,0,8);
#
#  Activate the workstations.
#
&NCAR::gacwk($IWKID);
&NCAR::gacwk($IWKID2);
#
#  Draw a text string.
#
&NCAR::gtx(.5,.5,'Text');
&NCAR::frame;
#
#  Close things down.
#
&NCAR::gdawk($IWKID);
&NCAR::gdawk($IWKID2);
&NCAR::gclwk($IWKID);
&NCAR::gclwk($IWKID2);
&NCAR::gclks;
#





rename 'gmeta', 'ncgm/fgke01.ncgm';
