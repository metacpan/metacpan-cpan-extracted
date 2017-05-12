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
#  Positioning coordinates.
#
my ( $XL1, $XL2, $XL3 ) = ( 0.20, 0.50, 0.80 );
my ( $Y1, $Y2, $Y3, $Y4 ) = ( 0.83, 0.62, 0.40, 0.20 );
my ( $YL1, $YL2, $YL3, $YL4 ) = ( 0.74, 0.52, 0.32, 0.07 );
my $SIZLAB = .02;
#
#  Define a color table.
#
&NCAR::gscr(1, 0, 1.00, 1.00, 1.00);
&NCAR::gscr(1, 1, 0.00, 0.00, 0.00);
&NCAR::gscr(1, 2, 0.00, 0.00, 1.00);
&NCAR::gscr(1, 3, 0.00, 1.00, 0.00);
&NCAR::gscr(1, 4, 1.00, 0.00, 0.00);
&NCAR::gscr(1, 5, 1.00, 1.00, 0.00);
&NCAR::gscr(1, 6, 1.00, 0.65, 0.00);
&NCAR::gscr(1, 7, 0.85, 0.85, 0.85);
#
#  Plot title.
#
&NCAR::plchhq(0.50,0.95,':F26:Icons for daily weather',0.033,0.,0.)       ;
#
#  Cloudy.
#
&NCAR::wmseti( 'CC1 - cloud interior color ', 7 );
&NCAR::wmseti( 'CC2 - cloud outline color', 1 );
&NCAR::wmseti( 'CC3 - cloud shadow color', 2 );
&NCAR::wmsetr( 'SHT - size scale', 0.013 );
&NCAR::wmlabs($XL1,$Y2-0.025,'C');
&NCAR::plchhq($XL1,$YL2,':F22:Cloudy',$SIZLAB,0.,0.)       ;
#
#  Rain.
#
&NCAR::wmgeti( 'COL', my $ICOLD );
&NCAR::wmseti( 'COL - rain color', 1 );
&NCAR::wmsetr( 'SHT - size scale', 0.013 );
&NCAR::wmlabs($XL2,$Y2,'R');
&NCAR::wmseti( 'COL - restore default color', $ICOLD );
&NCAR::plchhq($XL2,$YL2,':F22:Rain',$SIZLAB,0.,0.)       ;
#
#  T-storms.
#
&NCAR::wmseti( 'LC1 - color of interior of lightening bolt ', 5 );
&NCAR::wmseti( 'LC2 - outline color of lightening bolt', 1 );
&NCAR::wmseti( 'LC3 - shadow color for lightening bolt', 1 );
&NCAR::wmsetr( 'SHT - size scale', 0.013 );
&NCAR::wmlabs($XL2,$Y4,'T');
&NCAR::plchhq($XL2+.02,$YL4,':F22:T-storms',$SIZLAB,0.,0.)       ;
#
#  Snow.
#
&NCAR::wmsetr( 'SHT - size scale', 0.013 );
&NCAR::wmlabs($XL3,$Y2,'SN');
&NCAR::plchhq($XL3,$YL2,':F22:Snow',$SIZLAB,0.,0.)       ;
#
#  Rain and snow.
#
&NCAR::wmsetr( 'SHT - size scale', 0.013 );
&NCAR::wmlabs($XL3,$Y3+0.01,'RS');
&NCAR::plchhq($XL3,$YL3,':F22:Rain and snow',$SIZLAB,0.,0.)       ;
#
#  Wind.
#
&NCAR::wmseti( 'COL', 2 );
&NCAR::wmsetr( 'SHT - size scale', 0.016 );
&NCAR::gslwsc(2.);
&NCAR::wmlabs($XL2,$Y1,'WIND');
&NCAR::plchhq($XL2,$YL1,':F22:Windy',$SIZLAB,0.,0.)       ;
&NCAR::wmseti( 'COL', 1 );
&NCAR::gslwsc(1.);
#
#  Mostly cloudy.
#
&NCAR::wmseti( 'SC1 - color of the sun center', 5 );
&NCAR::wmseti( 'SC2 - color of the sun star points', 6 );
&NCAR::wmseti( 'SC3 - color of the sun outlines', 1 );
&NCAR::wmseti( 'SC4 - sun shadow color', 1 );
&NCAR::wmsetr( 'SHT - size scale', 0.013 );
&NCAR::wmlabs($XL1,$Y3,'MC');
&NCAR::plchhq($XL1,$YL3,':F22:Mostly cloudy',$SIZLAB,0.,0.)       ;
#
#  Sunny.
#
&NCAR::wmsetr( 'SHT - size scale', 0.013 );
&NCAR::wmlabs($XL1,$Y1,'SU');
&NCAR::plchhq($XL1,$YL1,':F22:Sunny',$SIZLAB,0.,0.)       ;
#
#  Mostly sunny.
#
&NCAR::wmsetr( 'SHT - size scale', 0.013 );
&NCAR::wmlabs($XL2,$Y3,'MS');
&NCAR::plchhq($XL2,$YL3,':F22:Mostly sunny',$SIZLAB,0.,0.)       ;
#
#  Intermittent showers.
#
&NCAR::wmsetr( 'SHT - size scale', 0.012 );
&NCAR::wmlabs($XL3,$Y4+.01,'IS');
&NCAR::plchhq($XL3+0.02,$YL4+0.017,':F22:Intermittent',$SIZLAB,0.,0.)       ;
&NCAR::plchhq($XL3+0.02,$YL4-0.017,':F22:showers',$SIZLAB,0.,0.)       ;
#
#  Sun, possible T-storms.
#
&NCAR::wmsetr( 'SHT - size scale', 0.012 );
&NCAR::wmlabs($XL1,$Y4+.01,'IT');
&NCAR::plchhq($XL1+0.02,$YL4+0.017,':F22:Sun, possible',$SIZLAB,0.,0.)       ;
&NCAR::plchhq($XL1+0.02,$YL4-0.017,':F22:T-storms',$SIZLAB,0.,0.)       ;
#
#  Ice.
#
&NCAR::wmsetr( 'SHT - size scale', 0.013 );
&NCAR::wmlabs($XL3,$Y1,'IC');
&NCAR::plchhq($XL3,$YL1,':F22:Ice',$SIZLAB,0.,0.)       ;


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/wmex07.ncgm';
