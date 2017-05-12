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

my $X = zeroes float, 100;
my $Y = zeroes float, 100;
#
#  Define a small color table for the CGM workstation.
#
&NCAR::gscr(1, 0, 1.0, 1.0, 1.0);
&NCAR::gscr(1, 1, 0.4, 0.0, 0.4);
&NCAR::gscr(1, 2, 0.0, 0.0, 1.0);
#
#  Turn clipping off
#
&NCAR::gsclip(0);
#
#  Generate a straight line of 100 points.
#
for my $I ( 1 .. 100 ) {
  set( $X, $I-1, $I );
  set( $Y, $I-1, 10*$I );
}
#
#  Use SET to define normalization transformation 1 with linear
#  scaling in the X direction and log scaling in the Y direction.
#
&NCAR::set(.15,.85,.15,.85,1.,100.,10.,1000.,2);
#
#  Set line color to blue.
#
&NCAR::gsplci(2);
#
#  Initialize the AUTOGRAPH entry EZXY so that the frame is not 
#  advanced and the Y axis is logarithmic.
#
&NCAR::displa(2,0,2);
#
#  Output the polyline (X,Y) using EZXY.
#
&NCAR::ezxy($X,$Y,100,' ');
#
#  Establish the identity transformation for character plotting.
#
&NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
#
#  Title the plot using Plotchar.
#
&NCAR::pcseti( 'FN', 25 );
&NCAR::pcseti( 'CC', 2 );
&NCAR::plchhq(.5,.05,'Log Scaling with SPPS',.025,0.,0.);
#
&NCAR::frame;


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/pgkex24.ncgm';
