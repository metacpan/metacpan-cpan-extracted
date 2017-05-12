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
# INVOKE DEMO DRIVER
#
&coord1( my $IERR);

sub coord1 {
#
#  This example shows the mapping from GKS world coordinates to
#   GKS normalized device coordinates.
#
my $XCRA = zeroes float, 101;
my $YCRA = zeroes float, 101;
my ( $DSL, $DSR, $DSB, $DST ) = ( .59,.99,.40,.70 );
my ( $PFL, $PFR, $PFB, $PFT ) = ( .71,.98,.42,.69 );
&NCAR::gsclip (0);
&NCAR::gslwsc (2.);
#
# Employ the new high quality filled fonts in PLOTCHAR
#
&NCAR::pcsetc( 'FN', 'times-roman' );
&NCAR::pcsetc( 'FC', '%' );
#
&NCAR::set    (0.,1.,0.,1.,0.,1.,0.,1.,1);
#
&NCAR::plchhq (.50,.97,
               'Mapping from a window in the world coordinate system',
               .02,0.,0.);
&NCAR::plchhq (.50,.93,
               'to a viewport in the normalized device coordinate system',
               .02,0.,0.);
&NCAR::pcseti( 'FN', 21 );
&NCAR::plchhq (.50,.89,
               '(Used in calls to GKS routines like GCA, GFA, GPL, GPM, and GTX)'
               ,.016,0.,0.);
&NCAR::pcseti( 'FN', 29 );
&NCAR::plchhq (.50,.19,
               'The window is:  100., 1000., 100., 1000.',
               .015,0.,0.);
&NCAR::plchhq (.50,.15,
               'The viewport is:  .15, .95, .10, .90',
               .015,0.,0.);
&NCAR::set    (.01,.55,.29,.83,0.,1100.,0.,1100.,1);
&NCAR::pcseti( 'FN', 22 );
&NCAR::line   (   0.,   0.,1100.,   0.);
&NCAR::line   (1100.,   0.,1050.,  25.);
&NCAR::line   (1100.,   0.,1050., -25.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cfux(1100.)+.015),0.,'X',.015,0.,0.);
&NCAR::line   (   0.,   0.,   0.,1100.);
&NCAR::line   (   0.,1100.,  25.,1050.);
&NCAR::line   (   0.,1100., -25.,1050.);
&NCAR::plchhq (0.,&NCAR::cfuy(&NCAR::cfuy(1100.)+.015),'Y',.015,0.,0.);
&NCAR::line   ( 100., 100.,1000., 100.);
&NCAR::line   (1000., 100.,1000.,1000.);
&NCAR::line   (1000.,1000., 100.,1000.);
&NCAR::line   ( 100.,1000., 100., 100.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cfux(100.)+.005),&NCAR::cfuy(&NCAR::cfuy(1000.)-.02),
               'WINDOW',.01,0.,-1.);
&NCAR::plchhq (100.,&NCAR::cfuy(&NCAR::cfuy(100.)-.01),'100',.009,0.,0.);
&NCAR::plchhq (1000.,&NCAR::cfuy(&NCAR::cfuy(100.)-.01),'1000',.009,0.,0.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cfux(100.)-.005),100.,'100',.009,0.,1.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cfux(100.)-.005),1000.,'1000',.009,0.,1.);

for my $I ( 1 .. 101 ) {
  my $xcra = 200 + 7 * ( $I - 1 );
  set( $XCRA, $I - 1, $xcra );
  set( $YCRA, $I - 1, 550 + 425 * sin( exp( ( $xcra - 200 ) / 300 ) - 1 ) );
}
&NCAR::curve  ($XCRA,$YCRA,101);
my $XCLW=&NCAR::cfux(100.);
my $XCRW=&NCAR::cfux(1000.);
my $YCBW=&NCAR::cfuy(100.);
my $YCTW=&NCAR::cfuy(1000.);
&NCAR::set    ($DSL,$DSR,$DSB,$DST,0.,1.,0.,1.,1);
&NCAR::line   (0.,0.,1.,0.);
&NCAR::line   (1.,0.,1.,1.);
&NCAR::line   (1.,1.,0.,1.);
&NCAR::line   (0.,1.,0.,0.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cfux(0.)+.005),&NCAR::cfuy(&NCAR::cfuy(1.)-.01),
              'DEVICE',.01,0.,-1.);
&NCAR::set    ($PFL,$PFR,$PFB,$PFT,0.,1.,0.,1.,1);
&NCAR::line   (0.,0.,1.,0.);
&NCAR::line   (1.,0.,1.,1.);
&NCAR::line   (1.,1.,0.,1.);
&NCAR::line   (0.,1.,0.,0.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cfux(0.)+.005),&NCAR::cfuy(&NCAR::cfuy(1.)-.01),
              'PLOTTER FRAME',.01,0.,-1.);
&NCAR::plchhq (0.,&NCAR::cfuy(&NCAR::cfuy(0.)-.01),'0',.008,0.,0.);
&NCAR::plchhq (1.,&NCAR::cfuy(&NCAR::cfuy(0.)-.01),'1',.008,0.,0.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cfux(0.)-.005),0.,'0',.008,0.,1.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cfux(0.)-.005),1.,'1',.008,0.,1.);
my $VPL=$PFL+.15*($PFR-$PFL);
my $VPR=$PFL+.95*($PFR-$PFL);
my $VPB=$PFB+.10*($PFT-$PFB);
my $VPT=$PFB+.90*($PFT-$PFB);
&NCAR::set    ($VPL,$VPR,$VPB,$VPT, 100.,1000., 100.,1000.,1);
&NCAR::line   ( 100., 100.,1000., 100.);
&NCAR::line   (1000., 100.,1000.,1000.);
&NCAR::line   (1000.,1000., 100.,1000.);
&NCAR::line   ( 100.,1000., 100., 100.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cfux(100.)+.005),&NCAR::cfuy(&NCAR::cfuy(1000.)-.01),
               'VIEWPORT',.01,0.,-1.);
&NCAR::plchhq (100.,&NCAR::cfuy(&NCAR::cfuy(100.)-.01),'.15',.008,0.,0.);
&NCAR::plchhq (1000.,&NCAR::cfuy(&NCAR::cfuy(100.)-.01),'.95',.008,0.,0.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cfux(100.)-.005),100.,'.10',.008,0.,1.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cfux(100.)-.005),1000.,'.90',.008,0.,1.);
&NCAR::curve  ($XCRA,$YCRA,101);
my $XCLV=&NCAR::cfux(100.);
my $XCRV=&NCAR::cfux(1000.);
my $YCBV=&NCAR::cfuy(100.);
my $YCTV=&NCAR::cfuy(1000.);
&NCAR::set    (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plotit (0,0,0);
&NCAR::dashdc ('$\'\'',3,1);
&NCAR::lined  ($XCLW,$YCBW,$XCLV,$YCBV);
&NCAR::lined  ($XCRW,$YCBW,$XCRV,$YCBV);
&NCAR::lined  ($XCRW,$YCTW,$XCRV,$YCTV);
&NCAR::lined  ($XCLW,$YCTW,$XCLV,$YCTV);
&NCAR::frame();
}



&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/fcoord1.ncgm';
