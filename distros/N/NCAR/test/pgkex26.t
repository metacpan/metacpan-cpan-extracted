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
#  Illustrate creating multiple metafiles in the same job.
#
my $XA = float [ 0, 1 ];
my $YA = float [ 0, 1 ];
#
#  Open GKS.
#
&NCAR::gopks (6,my $IDUM);
#
#  Open and activate a metafile with the name META01.
#
&NCAR::ngsetc('ME','META01');
&NCAR::gopwk (1, 2, 1);
&NCAR::gacwk (1);
#
#  Draw a single red line in the only frame in META01 .
#
&NCAR::gscr(1,1,1.,0.,0.);
&NCAR::gsplci(1);
&NCAR::gpl(2,$XA,$YA);
&NCAR::frame;
#
#  Deactivate and close the META01 metafile.
#
&NCAR::gdawk (1);
&NCAR::gclwk (1);
#
#  Open and activate META02.
#
&NCAR::ngsetc('ME','META02');
&NCAR::gopwk (1, 2, 1);
&NCAR::gacwk (1);
#
#  Draw a single green line in the only frame in META02 (all color
#  table entries have to be redefined).
#
&NCAR::gscr(1,2,0.,1.,0.);
&NCAR::gsplci(2);
&NCAR::gpl(2,$XA,$YA);
&NCAR::frame;
#
#  Deactivate and close the META02 metafile.
#
&NCAR::gdawk (1);
&NCAR::gclwk (1);
#
#  Close GKS.
#
&NCAR::gclks;


rename 'META01', 'ncgm/pgkex26.META01.ncgm';
rename 'META02', 'ncgm/pgkex26.META02.ncgm';
