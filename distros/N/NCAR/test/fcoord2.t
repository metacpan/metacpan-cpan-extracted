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
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
#  This example shows the mapping from NCAR Grapics user coordinates to
#   GKS normalized device coordinates.
#
my $XCRA = zeroes float, 101;
my $YCRA = zeroes float, 101;
my ( $DSL,$DSR,$DSB,$DST ) = ( .59,.99,.40,.70 );
my ( $PFL,$PFR,$PFB,$PFT ) = ( .71,.98,.42,.69 );
&NCAR::gsclip (0);
&NCAR::gslwsc (2.);
#
# Employ the new high quality filled fonts in PLOTCHAR
#
&NCAR::pcsetc('FN','times-roman');
#
&NCAR::set    (0.,1.,0.,1.,0.,1.,0.,1.,1);
#
&NCAR::pcsetc('FC','%');
&NCAR::plchhq (.50,.98,'Mapping from a window in the user coordinate system',02,0.,0.);
&NCAR::plchhq (.50,.94,'to a viewport in the normalized device coordinate system',.02,0.,0.);
&NCAR::plchhq (.50,.90,'using a transformation defined by calling SET',.02,0.,0.);
&NCAR::pcseti('FN',21);
&NCAR::plchhq (.50,.86,'(Used in calls to most NCAR Graphics routines)',.016,0.,0.);
&NCAR::pcseti('FN',29);
&NCAR::plchhq (.50,.22,'Assume a CALL SET (.15,.95,.10,.90,1000.,100.,100.,1000.,2).',.013,0.,0.);
&NCAR::plchhq (.50,.185,'The GKS viewport is:  .15, .95, .10, .90',.013,0.,0.);
&NCAR::plchhq (.50,.15,'The GKS window is:  100., 1000., 2., 3.',.013,0.,0.);
&NCAR::plchhq (.50,.115,'The value of \'MI\' is 3 (mirror-imaging of X\'s).',.013,0.,0.);
&NCAR::plchhq (.50,.08,'The value of \'LS\' is 2 (log scaling of Y\'s).',.013,0.,0.);
&NCAR::pcseti('FN',22);
&NCAR::set    (.01,.55,.29,.83,0.,1100.,0.,1100.,1);
&NCAR::line   (   0.,   0.,1100.,   0.);
&NCAR::line   (1100.,   0.,1050.,  25.);
&NCAR::line   (1100.,   0.,1050., -25.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cufx(1100.)+.015),0.,'X',.015,0.,0.);
&NCAR::line   (   0.,   0.,   0.,1100.);
&NCAR::line   (   0.,1100.,  25.,1050.);
&NCAR::line   (   0.,1100., -25.,1050.);
&NCAR::plchhq (0.,&NCAR::cfuy(&NCAR::cufy(1100.)+.015),'Y',.015,0.,0.);
&NCAR::line   ( 100., 100.,1000., 100.);
&NCAR::line   (1000., 100.,1000.,1000.);
&NCAR::line   (1000.,1000., 100.,1000.);
&NCAR::line   ( 100.,1000., 100., 100.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cufx(100.)+.005),&NCAR::cfuy(&NCAR::cufy(1000.)-.01),'WINDOW',.01,0.,-1.);
&NCAR::plchhq (100.,&NCAR::cfuy(&NCAR::cufy(100.)-.01),'100',.008,0.,0.);
&NCAR::plchhq (1000.,&NCAR::cfuy(&NCAR::cufy(100.)-.01),'1000',.008,0.,0.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cufx(100.)-.005),100.,'100',.008,0.,1.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cufx(100.)-.005),1000.,'1000',.008,0.,1.);
for my $I ( 1 .. 101 ) {
  my $xcra = 200.+7.*($I-1);
  set( $XCRA, $I-1, $xcra );
  set( $YCRA, $I-1, 200.+700.*(exp(log(10)*($xcra-200.)/700.)-1.)/9.+100.*sin(($xcra-200.)/30.) );
}
&NCAR::curve  ($XCRA,$YCRA,101);
my $XCLW=&NCAR::cufx(100.);
my $XCRW=&NCAR::cufx(1000.);
my $YCBW=&NCAR::cufy(100.);
my $YCTW=&NCAR::cufy(1000.);
&NCAR::plotit (0,0,0);
&NCAR::gslwsc (1.);
&NCAR::line (100.,200.,1000.,200.);
&NCAR::line (100.,300.,1000.,300.);
&NCAR::line (100.,400.,1000.,400.);
&NCAR::line (100.,500.,1000.,500.);
&NCAR::line (100.,600.,1000.,600.);
&NCAR::line (100.,700.,1000.,700.);
&NCAR::line (100.,800.,1000.,800.);
&NCAR::line (100.,900.,1000.,900.);
&NCAR::line (200.,100.,200.,1000.);
&NCAR::line (300.,100.,300.,1000.);
&NCAR::line (400.,100.,400.,1000.);
&NCAR::line (500.,100.,500.,1000.);
&NCAR::line (600.,100.,600.,1000.);
&NCAR::line (700.,100.,700.,1000.);
&NCAR::line (800.,100.,800.,1000.);
&NCAR::line (900.,100.,900.,1000.);
&NCAR::plotit (0,0,0);
&NCAR::gslwsc (2.);
&NCAR::set    ($DSL,$DSR,$DSB,$DST,0.,1.,0.,1.,1);
&NCAR::line   (0.,0.,1.,0.);
&NCAR::line   (1.,0.,1.,1.);
&NCAR::line   (1.,1.,0.,1.);
&NCAR::line   (0.,1.,0.,0.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cufx(0.)+.005),&NCAR::cfuy(&NCAR::cufy(1.)-.01),'DEVICE',.01,0.,-1.);
&NCAR::set    ($PFL,$PFR,$PFB,$PFT,0.,1.,0.,1.,1);
&NCAR::line   (0.,0.,1.,0.);
&NCAR::line   (1.,0.,1.,1.);
&NCAR::line   (1.,1.,0.,1.);
&NCAR::line   (0.,1.,0.,0.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cufx(0.)+.005),&NCAR::cfuy(&NCAR::cufy(1.)-.01),'PLOTTER FRAME',.01,0.,-1.);
&NCAR::plchhq (0.,&NCAR::cfuy(&NCAR::cufy(0.)-.01),'0',.008,0.,0.);
&NCAR::plchhq (1.,&NCAR::cfuy(&NCAR::cufy(0.)-.01),'1',.008,0.,0.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cufx(0.)-.005),0.,'0',.008,0.,1.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cufx(0.)-.005),1.,'1',.008,0.,1.);
my $VPL=$PFL+.15*($PFR-$PFL);
my $VPR=$PFL+.95*($PFR-$PFL);
my $VPB=$PFB+.10*($PFT-$PFB);
my $VPT=$PFB+.90*($PFT-$PFB);
&NCAR::set    ($VPL,$VPR,$VPB,$VPT,1000., 100., 100.,1000.,2);
&NCAR::line   (1000., 100., 100., 100.);
&NCAR::line   ( 100., 100., 100.,1000.);
&NCAR::line   ( 100.,1000.,1000.,1000.);
&NCAR::line   (1000.,1000.,1000., 100.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cufx(1000.)+.005),&NCAR::cfuy(&NCAR::cufy(1000.)-.01),'VIEWPORT',.01,0.,-1.);
&NCAR::plchhq (1000.,&NCAR::cfuy(&NCAR::cufy(100.)-.01),'.15',.008,0.,0.);
&NCAR::plchhq (100.,&NCAR::cfuy(&NCAR::cufy(100.)-.01),'.95',.008,0.,0.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cufx(1000.)-.005),100.,'.10',.008,0.,1.);
&NCAR::plchhq (&NCAR::cfux(&NCAR::cufx(1000.)-.005),1000.,'.90',.008,0.,1.);
&NCAR::curve  ($XCRA,$YCRA,101);
&NCAR::plotit (0,0,0);
&NCAR::gslwsc (1.);
&NCAR::line (100.,200.,1000.,200.);
&NCAR::line (100.,300.,1000.,300.);
&NCAR::line (100.,400.,1000.,400.);
&NCAR::line (100.,500.,1000.,500.);
&NCAR::line (100.,600.,1000.,600.);
&NCAR::line (100.,700.,1000.,700.);
&NCAR::line (100.,800.,1000.,800.);
&NCAR::line (100.,900.,1000.,900.);
&NCAR::line (200.,100.,200.,1000.);
&NCAR::line (300.,100.,300.,1000.);
&NCAR::line (400.,100.,400.,1000.);
&NCAR::line (500.,100.,500.,1000.);
&NCAR::line (600.,100.,600.,1000.);
&NCAR::line (700.,100.,700.,1000.);
&NCAR::line (800.,100.,800.,1000.);
&NCAR::line (900.,100.,900.,1000.);
&NCAR::plotit (0,0,0);
&NCAR::gslwsc (2.);
my $XCLV=&NCAR::cufx(1000.);
my $XCRV=&NCAR::cufx(100.);
my $YCBV=&NCAR::cufy(100.);
my $YCTV=&NCAR::cufy(1000.);
&NCAR::set    (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plotit (0,0,0);
&NCAR::gslwsc (1.);
&NCAR::dashdc ('$\'',3,1);
&NCAR::lined  ($XCLW,$YCBW,$XCRV,$YCBV);
&NCAR::lined  ($XCRW,$YCBW,$XCLV,$YCBV);
&NCAR::lined  ($XCRW,$YCTW,$XCLV,$YCTV);
&NCAR::lined  ($XCLW,$YCTW,$XCRV,$YCTV);
&NCAR::frame;

 
print STDERR "
COORD2 TEST SUCCESSFUL
SEE PLOTS TO VERIFY PERFORMANCE
";


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fcoord2.ncgm';
