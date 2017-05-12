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
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
#  This test program is an example of X axis scale reversal
#  in the NCAR Graphics User Coordinate System.
#
#
#       Dimension a line of 100 points
#
my $X = zeroes float, 100;
my $Y = zeroes float, 100;

#
#       Turn clipping off
#
&NCAR::gsclip(0);
#
#       Generate a straight line of 100 points.
#
for my $I ( 1 .. 100 ) {
  set( $X, $I-1, $I );
  set( $Y, $I-1, 10*$I );
}
#
#       Select the normalization transformation
#        window and viewport.  Reverse X in the window.
#
&NCAR::set(.10,.95,.20,.95,100.,1.,10.,1000.,1);
#
#       Set attributes for output
#        Assign yellow to color index 2
#
&NCAR::gscr(1,0,0.,0.,0.);
&NCAR::gscr(1,1,1.,1.,1.);
&NCAR::gscr(1,2,1.,1.,0.);
#
#       Generate output (GKS, SPPS, or NCAR utilities)
#
#         Set polyline color index to yellow
#
&NCAR::gsplci(2);
#
#         Initialize the AUTOGRAPH entry EZXY so that
#         the frame is not advanced.
#
&NCAR::displa(2,0,1);
#
#         Tell EZXY that the SET ordering of the window
#         is to be used (LSET 3 or 4).
#
&NCAR::anotat(' ',' ',1,4,0,[]);
#
#         Output the polyline (X,Y) using EZXY.
#
&NCAR::ezxy($X,$Y,100,' ');
#
#       Add a yellow title.
#
#        PLOTCHAR uses stroked characters; thus, the yellow polyline
#        color index previously set will still apply.
#
#       Return the window to fractional coordinates for the title.
#
&NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plchhq(0.5,.05,'Example 5.2.  X Axis Reversal with SPPS',.019,0.,0.);
#
#       Advance the frame to ensure all output is plotted
#

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/sprevx.ncgm';
