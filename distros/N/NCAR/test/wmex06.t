# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use NCAR;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
unlink( 'gmeta' );

use PDL;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

&NCAR::gscr( 1, 0, 1.0, 1.0, 1.0 );
&NCAR::gscr( 1, 1, 0.0, 0.0, 0.0 );
&NCAR::gscr( 1, 2, 1.0, 0.0, 0.0 );
&NCAR::gscr( 1, 3, 0.0, 0.0, 1.0 );
&NCAR::gscr( 1, 4, 0.0, 1.0, 0.0 );
&NCAR::gscr( 1, 5, 0.9, 0.9, 0.9 );
&NCAR::gscr( 1, 6, 1.0, 1.0, 0.0 );

&NCAR::plchhq( 0.50, 0.94, ":F26:Symbols and labels", 0.033, 0., 0. );

my $xe = 0;

my $yy = 0.83;
my $yinc = 0.17;
my $xinc = 0.12;
&NCAR::pcsetc( 'FC', '%' );
&NCAR::plchhq(0.05,$yy,'%F26%HIs and LOWs:',0.025,0.,-1.);
&NCAR::pcsetc( 'FC', ':' );
&NCAR::pcgetr( 'XE', $xe );

$xe = $xe+0.5*$xinc;

&NCAR::wmseti( 'HIS - shadow color for high symbols', 1 );
&NCAR::wmseti( 'HIB - background color for high symbols', 0 );
&NCAR::wmseti( 'HIF - character color for high symbols', 1 );
&NCAR::wmseti( 'HIC - character color for circumscribed circle', 1 );
&NCAR::wmlabs( $xe, $yy, 'HI' );
$xe = $xe + $xinc;

&NCAR::wmsetr( 'SHT', 0.04 );
&NCAR::wmseti( 'HIS - shadow color for high symbols', 3 );
&NCAR::wmseti( 'HIB - background color for high symbols', 5 );
&NCAR::wmseti( 'HIF - character color for high symbols', 2 );
&NCAR::wmseti( 'HIC - character color for circumscribed circle', 4 );
&NCAR::wmlabs($xe,$yy,'HI');
$xe = $xe + $xinc;

&NCAR::wmsetr( 'SHT', 0.02 );
&NCAR::wmseti( 'LOS - shadow color for low symbols', 5 );
&NCAR::wmseti( 'LOB - background color for low symbols', 1 );
&NCAR::wmseti( 'LOF - character color for low symbols', 0 );
&NCAR::wmlabs($xe,$yy,'LOW');
$xe = $xe + $xinc;

&NCAR::wmsetr( 'SHT', 0.04 );
&NCAR::wmseti( 'LOS - shadow color for low symbols', 2 );
&NCAR::wmseti( 'LOB - background color for low symbols', 5 );
&NCAR::wmseti( 'LOF - character color for low symbols', 3 );
&NCAR::wmlabs($xe,$yy,'LOW');


$yy = $yy - $yinc;
&NCAR::pcsetc( 'FC - Function code character', '%' );
&NCAR::plchhq(0.05,$yy,'%F26%Arrows:',0.025,0.,-1.);
&NCAR::pcsetc( 'FC', ':' );
&NCAR::pcgetr( 'XE - coordinate of end of last string', $xe );
$xe = $xe + 0.05;
&NCAR::wmsetr( 'ARD - arrow direction', 270. );
&NCAR::wmlabs($xe,$yy-0.02,'Arrow');

$xe = $xe + 0.1;

&NCAR::wmsetr( 'ARS - arrow size', .1 );
&NCAR::wmsetr( 'ARD - arrow direction', 55. );
&NCAR::wmsetr( 'ARL - scale factor for length of arrow tail', 1. );
&NCAR::wmseti( 'AWC - color index for interior of arrow', 2 );
&NCAR::wmlabs($xe,$yy+0.05,'Arrow');

$xe = $xe + 0.04;

&NCAR::gslwsc(2.);
&NCAR::wmsetr( 'ARS - arrow size', .2 );
&NCAR::wmsetr( 'ARD - arrow direction', 180. );
&NCAR::wmsetr( 'ARL - scale factor for length of arrow tail', 0.6 );
&NCAR::wmseti( 'AWC - color index for interior of arrow', 0 );
&NCAR::wmseti( 'AOC - color index for arrow outline', 3 );
&NCAR::wmlabs($xe,$yy,'Arrow');


$xe = $xe + 0.18;

&NCAR::wmsetr( 'ARD - arrow direction', 270. );
&NCAR::wmseti( 'AWC - color index for interior of arrow', 2 );
&NCAR::gslwsc(2.);
&NCAR::wmlabs($xe,$yy-0.05,'Arrow');
&NCAR::gslwsc(1.);

$xe = $xe + 0.18;

&NCAR::wmsetr( 'ARD - arrow direction', 0. );
&NCAR::wmseti( 'AWC - color index for interior of arrow', 5 );
&NCAR::wmseti( 'AOC - color index for arrow outline', 2 );
&NCAR::wmseti( 'ASC - color index for arrow shadow', 3 );
&NCAR::wmlabs($xe,$yy,'Arrow');

$xe = $xe + 0.03;

&NCAR::wmdflt();
&NCAR::wmsetr( 'ARS - arrow size', .1 );
&NCAR::wmsetr( 'ARD - arrow direction', 180. );
&NCAR::wmsetr( 'ARL - scale factor for length of arrow tail', 1.8 );
&NCAR::wmlabs($xe,$yy,'Arrow');


$yy = $yy - $yinc;
&NCAR::pcsetc( 'FC', '%' );
&NCAR::plchhq(0.05,$yy,'%F26%Dots and City info:',0.025,0.,-1.);
&NCAR::pcsetc( 'FC', ':' );
&NCAR::pcgetr( 'XE', $xe );
$xe = $xe + 0.05;

&NCAR::wmseti( 'DBC - color index for dot shadow', 2 );
&NCAR::wmseti( 'DTC - color index for dot', 3 );
&NCAR::wmsetr( 'DTS - size of dot', 0.012 );
&NCAR::wmlabs($xe,$yy,'DOT');
$xe = $xe + 0.10;

&NCAR::wmseti( 'RFC - color index for city labels', 3 );
&NCAR::wmseti( 'CBC - color index background of city labels', 0 );
&NCAR::wmsetr( 'CHT - size of city labels', .02 );
&NCAR::wmsetr( 'CMG - margins for city labels', .006 );
&NCAR::wmlabc($xe,$yy,'Boulder','83/68');
$xe = $xe + 0.15;

&NCAR::wmseti( 'DBC - color index for dot shadow', 5 );
&NCAR::wmseti( 'DTC - color index for dot', 1 );
&NCAR::wmsetr( 'DTS - size of dot', 0.024 );
&NCAR::wmlabs($xe,$yy,'DOT');
$xe = $xe + 0.12;

&NCAR::wmseti( 'RFC - color index for city labels', 6 );
&NCAR::wmseti( 'CBC - color index background of city labels', 3 );
&NCAR::wmsetr( 'CHT - size of city labels', .03 );
&NCAR::wmsetr( 'CMG - margins for city labels', .006 );
&NCAR::wmlabc($xe,$yy,'Tulsa','103/83');


$yy = $yy - $yinc;
&NCAR::pcsetc( 'FC', '%' );
&NCAR::plchhq(0.05,$yy,'%F26%Regional labels:',0.025,0.,-1.);
&NCAR::pcsetc( 'FC', ':' );
&NCAR::pcgetr( 'XE', $xe );
$xe = $xe + 0.13;

&NCAR::wmsetr( 'WHT - size of label', 0.02 );
&NCAR::wmlabw($xe,$yy,'TORRID');
$xe = $xe + 0.30;

&NCAR::wmseti( 'RC1 - color index for box outline', 4 );
&NCAR::wmseti( 'RC2 - color index for character background', 5 );
&NCAR::wmseti( 'RC3 - color index for box shadow', 1 );
&NCAR::wmseti( 'RC4 - color index for text', 3 );
&NCAR::wmseti( 'RC5 - color index for text outlines', 2 );
&NCAR::wmsetr( 'WHT - size of label', 0.035 );
&NCAR::wmlabw($xe,$yy,'FREEZING');


$yy = $yy - $yinc;
&NCAR::pcsetc( 'FC', '%' );
&NCAR::plchhq(0.05,$yy,'%F26%Regional temps.:',0.025,0.,-1.);
&NCAR::pcsetc( 'FC', ':' );
&NCAR::pcgetr( 'XE', $xe );
$xe = $xe + 0.07;


&NCAR::wmdflt();
&NCAR::wmsetr( 'THT - Height of regional temperature labels', 0.032 );
&NCAR::wmseti( 'RFC - primary character color', 2 );
&NCAR::wmlabt($xe,$yy,'80s',0);
$xe = $xe + 0.12;

&NCAR::wmsetr( 'ARS - arrow size', 0.07 );
&NCAR::wmseti( 'ROS - color index for character outlines', 0 );
&NCAR::wmseti( 'RFC - primary character color', 2 );
&NCAR::wmseti( 'RLS - color index for shadows', 1 );
&NCAR::wmlabt($xe,$yy,'80s',2);
$xe = $xe + 0.03;

&NCAR::wmseti( 'ROS - color index for character outlines', 1 );
&NCAR::wmseti( 'RFC - primary character color', 0 );
&NCAR::wmseti( 'RLS - color index for shadows', 1 );
&NCAR::wmlabt($xe,$yy,'80s',6);
$xe = $xe + 0.15;

&NCAR::wmseti( 'ROS - color index for character outlines', -1 );
&NCAR::wmseti( 'RFC - primary character color', 2 );
&NCAR::wmseti( 'RLS - color index for shadows', -1 );
&NCAR::wmseti( 'RBS - color index for backgrounds for labels', 1 );
&NCAR::wmsetr( 'RMG - size of margins around characters', 0.01 );
&NCAR::wmlabt($xe,$yy,'80s',0);



&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/wmex06.ncgm';
