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
use strict;
   
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 8, 1 );
my ( $IWKID1, $IWKID2 ) = ( 5, 7 );
#
#  Illustrate workstation control functions by intermixing plotting to
#  a metafile with plotting to X window workstations.
#
#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
#
#  Define color index 6 as red on that workstation.
#
&NCAR::gscr($IWKID,6,1.,0.,0.);
#
#  Set character height and set the text alignment to (center, half).
#
&NCAR::gschh(.04);
&NCAR::gstxal(2,3);
#
#  Activate the CGM workstation.
#
&NCAR::gacwk($IWKID);
#
#  Create picture 1 in the metafile and call FRAME to terminate 
#  the first picture.
#
&NCAR::gstxci(6);
&NCAR::gtx(.5,.5,'Picture 1');
&NCAR::frame;
#
#  Put another picture in the metafile.
#
&NCAR::gtx(.5,.5,'Picture 2');
&NCAR::frame;
#
#  Open and activate an X11 workstation and define color index 6
#  to be cyan on that workstation (this workstation will be referred 
#  to as "The first window".
#
&NCAR::gopwk($IWKID1,0,8);
&NCAR::gacwk($IWKID1);
&NCAR::gscr($IWKID1,6,0.,1.,1.);
#
#  Create picture 3.  This will be plotted to the CGM workstation as
#  well as to the X11 window since they are both active.
#
&NCAR::gtx(.5,.5,'Picture 3');
#
#  Terminate the metafile picture.
#
&NCAR::ngpict($IWKID,1);
#
#  Pause in the X window with a "<READY>" prompt and wait for a 
#  mouse click.  The window will be cleared after the mouse click.
#
&NCAR::ngpict($IWKID1,4);
#
#  Open and activate another X workstation (to be reffered to as "The
#  second window") and define color index 6 to be green on that 
#  workstation.
#
&NCAR::gopwk($IWKID2,0,8);
&NCAR::gacwk($IWKID2);
&NCAR::gscr($IWKID2,6,0.,1.,0.);
#
#  Plot picture 4.  This will be sent to the CGM workstation and the
#  two X window workstations since they are all active.
#
&NCAR::gtx(.5,.5,'Picture 4');
#
#  Terminate picture 4 in the metafile.
#
&NCAR::ngpict($IWKID,1);
#
#  Make the second window current.
#
&NCAR::ngpict($IWKID2,0);
#
#  Pause in the first window with a "<READY>" prompt and wait for a
#  mouse click.  The window will be cleared after the click.
#
&NCAR::ngpict($IWKID1,4);
#
#  Clear the second window.
#
&NCAR::ngpict($IWKID2,1);
#
#  Deactivate the metafile (but do not close it) and draw picture 5.
#  This will go to the two active X11 workstations, but not the CGM.
#
&NCAR::gdawk($IWKID);
&NCAR::gtx(.5,.5,'Picture 5');
#
#  Make the second window current
#
&NCAR::ngpict($IWKID2,0);
#
#  Pause in the first window waiting or a mouse click
#
&NCAR::ngpict($IWKID1,4);
#
#  Re-activate the metafile and deactivate the second window.
#
&NCAR::gacwk($IWKID);
&NCAR::gdawk($IWKID2);
#
#  Plot picture 6.  This will go to the first window and to the
#  metafile.
#
&NCAR::gtx(.5,.5,'Picture 6');
#
#  Terminate the picture in the CGM.
#
&NCAR::ngpict($IWKID,1);
#
#  Pause in the first window waiting for a mouse click.
#
&NCAR::ngpict($IWKID1,4);
#
#  Reactivate the second window and clear it.
#
&NCAR::gacwk($IWKID2);
&NCAR::ngpict($IWKID2,1);
#
#  Put out picture 7.  This will go to the all active workstations.
#
&NCAR::gtx(.5,.5,'Picture 7');
#
#  Terminate the picture in the CGM.
#
&NCAR::ngpict($IWKID,1);
#
#  Make the first window current.
#
&NCAR::ngpict($IWKID1,0);
#
#  Pause in the second window waiting for a mouse click.
#
&NCAR::ngpict($IWKID2,4);
#
#  Deactivate and close the first window; deactivate and close the CGM.
# 
&NCAR::gdawk($IWKID1);
&NCAR::gdawk($IWKID);
&NCAR::gclwk($IWKID1);
&NCAR::gclwk($IWKID);
#
#  Put out picture 8.  This will go to the second window, the only 
#  active workstation.
#
&NCAR::gtx(.5,.5,'Picture 8');
#
#  Pause in the second window with a "<READY>" prompt.
#
&NCAR::ngpict($IWKID2,4);
#
#  Deactivate and close the second window.
#
&NCAR::gdawk($IWKID2);
&NCAR::gclwk($IWKID2);
#
#  Close GKS.
#
&NCAR::gclks;
