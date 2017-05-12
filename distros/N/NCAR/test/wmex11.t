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

sub exstnm {

  my ( $X, $Y ) = @_;
#
#  Convert X and Y to NDC and work in NDC space.
#
my $XNDC = float [ 0 ];
my $YNDC = float [ 0 ];
&NCAR::wmw2nx(1, float( [ $X ] ), $XNDC);
&NCAR::wmw2ny(1, float( [ $Y ] ), $YNDC);
#
#  Draw a wind barb at 320 degrees and cloud cover symbol.
#
my $xdnc = at( $XNDC, 0 );
my $ydnc = at( $YNDC, 0 );
&NCAR::wmseti( 'WBF', 1 );
&NCAR::wmbarb( $xdnc, $ydnc,-5.,8.66);
&NCAR::wmgetr( 'WBC', my $WBC );
&NCAR::wmgetr( 'WBS', my $WBSHFT );
&NCAR::ngwsym('N',0, $xdnc, $ydnc, $WBC*$WBSHFT,1,0);
#
my $SIZ = 0.15*$WBSHFT;
&NCAR::pcseti( 'FN', 21 );
&NCAR::plchhq( $xdnc, $ydnc, 'N', $SIZ,0.,0.);
#
#  Direction
#
&NCAR::wmseti( 'RBS', 0 );
&NCAR::wmsetr( 'RMG', .030*$WBSHFT );
&NCAR::wmsetr( 'THT', 0.8*$SIZ );
&NCAR::wmlabt($xdnc-0.7*$WBSHFT*0.5,$ydnc+0.7*$WBSHFT*0.866,'dd',0);
#
#  Wind speed
#
&NCAR::wmlabt($xdnc-0.92*$WBSHFT*0.5,$ydnc+0.7*$WBSHFT*1.5,'ff',0);
#
#  High clouds (CH).
#
&NCAR::plchhq($xdnc,$ydnc+0.83*$WBSHFT,'C:B1:H',$SIZ,0.,0.);
#
#  Medium clouds (CM).
#
&NCAR::plchhq($xdnc,$ydnc+0.47*$WBSHFT,'C:B1:M',$SIZ,0.,0.);
#
#  Current temperature (TT).
#
&NCAR::plchhq($xdnc-0.7*$WBSHFT,$ydnc+0.36*$WBSHFT,'TT',$SIZ,0.,0.);
#
#  Barometric pressure (ppp).
#
&NCAR::plchhq($xdnc+0.55*$WBSHFT,$ydnc+0.36*$WBSHFT,'ppp',$SIZ,0.,0.);
#
#  Visibility (VV).
#
&NCAR::plchhq($xdnc-.95*$WBSHFT,$ydnc,'VV',$SIZ,0.,0.);
#
#  Present weather (ww).
#
&NCAR::plchhq($xdnc-0.45*$WBSHFT,$ydnc,'ww',$SIZ,0.,0.);
#
#  Pressure change (pp).
#
&NCAR::plchhq($xdnc+0.5*$WBSHFT,$ydnc,'pp',$SIZ,0.,0.);
#
#  Pressure tendency (a).
#
&NCAR::plchhq($xdnc+$WBSHFT,$ydnc,'a',$SIZ,0.,0.);
#
#  Temperature of dewpoint (TD).
#
&NCAR::plchhq($xdnc-0.65*$WBSHFT,$ydnc-0.42*$WBSHFT,'T:B1:d',$SIZ,0.,0.);
#
#  Low clouds (CL).
#
&NCAR::plchhq($xdnc-0.17*$WBSHFT,$ydnc-0.42*$WBSHFT,'C:B1:L',$SIZ,0.,0.);
#
#  Sky cover (NH).
#
&NCAR::plchhq($xdnc+0.31*$WBSHFT,$ydnc-0.42*$WBSHFT,'N:B1:h',$SIZ,0.,0.);
#
#  Past weather (W).
#
&NCAR::plchhq($xdnc+0.75*$WBSHFT,$ydnc-0.42*$WBSHFT,'W',$SIZ,0.,0.);
#
#  Cloud height (h).
#
&NCAR::plchhq($xdnc-0.12*$WBSHFT,$ydnc-0.72*$WBSHFT,'h',$SIZ,0.,0.);
#
#  Precipitation in last 6 hours (RR).
#
&NCAR::plchhq($xdnc+0.53*$WBSHFT,$ydnc-0.72*$WBSHFT,'RR',$SIZ,0.,0.);
#
}

   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

my ( $X1, $X2 ) =  ( 0.22, 0.67 );

#
&NCAR::gscr(1,0,1.,1.,1.);
&NCAR::gscr(1,1,0.,0.,0.);
&NCAR::gscr(1,2,.4,0.,.4);
#
#  Symbolic station model
#
&NCAR::wmsetr( 'WBS', 0.20 );
&NCAR::gslwsc(3.);
&exstnm($X2,.73);
&NCAR::line(0.1,.5,0.9,.5);
&NCAR::plotit(0,0,0);
my $SIZ = 0.03;
&NCAR::pcseti( 'FN', 26 );
&NCAR::pcseti( 'CC', 2 );
&NCAR::plchhq($X1,.85,'SYMBOLIC',$SIZ,0.,0.);
&NCAR::plchhq($X1,.75,'STATION',$SIZ,0.,0.);
&NCAR::plchhq($X1,.65,'MODEL',$SIZ,0.,0.);
&NCAR::pcseti( 'CC', 1 );


#
#  Sample plotted report
#
my @IMDAT = ( 
 '11212',
 '83320',
 '10011',
 '20000',
 '30000',
 '40147',
 '52028',
 '60111',
 '77060',
 '86792',
);
&NCAR::wmstnm($X2,.23, \@IMDAT);
&NCAR::pcseti( 'FN', 26 );
&NCAR::pcseti( 'CC', 2 );


&NCAR::plchhq($X1,.35,'SAMPLE',$SIZ,0.,0.);
&NCAR::plchhq($X1,.25,'PLOTTED',$SIZ,0.,0.);
&NCAR::plchhq($X1,.15,'DATA',$SIZ,0.,0.);
&NCAR::pcseti( 'CC', 1 );
#



&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/wmex11.ncgm';
