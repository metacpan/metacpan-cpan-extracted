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
my $IWTYPE=1;
my $IWKID=1;
#
#  Define error file, Fortran unit number, and workstation type,
#  and workstation ID.
#
# PURPOSE                To provide a simple demonstration of the
#                        GFLASH package.
#
# I/O                    If there is a normal exit from GFLASH,
#                        the message
#
#                          GFLASH TEST SUCCESSFUL . . . SEE PLOTS TO
#                          VERIFY PERFORMANCE
#
#                        is written on unit 6
#
# NOTE                   The call to GOPWK will have to be modified
#                        when using a non-NCAR GKS package.  The third
#                        argument must be the workstation type for WISS.
#
#
#  Data for the border and two lines.
#
 
my @PERIMX = ( 0., 1., 1., 0., 0. );
my @PERIMY = ( 0., 0., 1., 1., 0. );

#

my @RLIN1X = ( .25,.75 );
my @RLIN1Y = ( .25,.75 );

#
my @RLIN2X = ( .75,.25 );
my @RLIN2Y = ( .25,.75 );

#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
#  Initialize the GFLASH package.  If using a non-NCAR GKS package
#  the final argument in the following call should be replaced with
#  the workstation type for WISS.
#
&NCAR::gopwk(9,1,3);
#
#  Establish character height and text alignment.
#
#
#  Put a line with positive slope into flash buffer 1.
#
&NCAR::gflas1(1);
&NCAR::gpl(2, float( \@RLIN1X ), float( \@RLIN1Y ) );
&NCAR::gflas2;
#
#  Put a line with negative slope into flash buffer 2.
#
&NCAR::gflas1(2);
&NCAR::gpl(2, float( \@RLIN2X ), float( \@RLIN2Y ) );
&NCAR::gflas2;
#
#  Draw the border.
#
&NCAR::gpl(5, float( \@PERIMX ), float( \@PERIMY ) );
#
#  Put the two segments into the picture.
#
&NCAR::gflas3(1);
&NCAR::gflas3(2);
&NCAR::frame;
#
#  Close the GFLASH package.
#
&NCAR::gclwk(9);
#
#  Deactivate and close the metafile workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks;



rename 'gmeta', 'ncgm/fgke02.ncgm';
