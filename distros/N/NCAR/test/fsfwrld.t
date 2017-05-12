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

my ( $NPTS, $LRWK, $LIWK ) = ( 101, 1000, 1000 );
my $IWRK = zeroes long, $LIWK;
my $X1 = zeroes float, $NPTS;
my $Y1 = zeroes float, $NPTS;
my $X2 = zeroes float, $NPTS;
my $Y2 = zeroes float, $NPTS;
my $X3 = zeroes float, $NPTS;
my $Y3 = zeroes float, $NPTS;
my $RWRK = zeroes float, $LRWK;
#
# Convert from degrees to radians.
#
my $D2R = .017453292519943;
#
#  Demonstrate the use of SFWRLD.
#
#  Generate three intersecting circles of radius 1.
for my $II ( 1 .. $NPTS ) {
  my $ANG=$D2R*3.6*($II-1);
  my $X=cos($ANG);
  my $Y=sin($ANG);
  set( $X1, $II-1, $X - .5 );
  set( $X2, $II-1, $X + .5 );
  set( $X3, $II-1, $X );
  set( $Y1, $II-1, $Y + .5 );
  set( $Y2, $II-1, $Y + .5 );
  set( $Y3, $II-1, $Y - .5 );
}
#
#  Define the entire Viewport and a Window from -2. to 2 with linear scaling.
#
&NCAR::set(0.,1.,0.,1.,-2.,2.,-2.,2.,1);
#
#  Process the area definitions (regions) and fill according to instructions
#
&NCAR::sfsetr ('SP',0.006);
&NCAR::sfsetr ('AN',0.);
&NCAR::sfwrld ($X1,$Y1,$NPTS,$RWRK,$LRWK,$IWRK,$LIWK);
&NCAR::sfsetr ('AN',45.);
&NCAR::sfwrld ($X2,$Y2,$NPTS,$RWRK,$LRWK,$IWRK,$LIWK);
&NCAR::sfsetr ('AN',90.);
&NCAR::sfwrld ($X3,$Y3,$NPTS,$RWRK,$LRWK,$IWRK,$LIWK);


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fsfwrld.ncgm';
