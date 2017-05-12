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

my @X = ( 0.40, 0.90 );
my @Y = ( 0.85, 0.85 );
my ( $DELY, $XP, $ALSIZ ) = ( 0.09, 0.375, 0.024 );

#
#  Define a color table.
#
&NCAR::gscr(1, 0, 1.0, 1.0, 1.0);
&NCAR::gscr(1, 1, 0.0, 0.0, 0.0);
&NCAR::gscr(1, 2, 1.0, 0.0, 0.0);
&NCAR::gscr(1, 3, 0.5, 0.0, 0.7);
&NCAR::gscr(1, 4, 0.0, 1.0, 0.0);
&NCAR::gscr(1, 5, 1.0, 0.5, 0.0);
&NCAR::gscr(1, 6, 0.0, 0.0, 1.0);
#
#  Plot title.
#
&NCAR::plchhq(0.50,0.95,':F26:Front Types',0.035,0.,0.);
#
#  Define some parameters.
#
&NCAR::wmsetr( 'LIN - line widths of warm/cold front lines', 3. );
&NCAR::wmsetr( 'BEG - space before first front symbol', 0.02 );
&NCAR::wmsetr( 'END - space after last front symbol', 0.02 );
&NCAR::wmsetr( 'BET - space between front symbols', .03 );
&NCAR::wmsetr( 'SWI - size of symbols on front line', .04 );
&NCAR::wmseti( 'WFC - color for warm front symbols', 2 );
&NCAR::wmseti( 'CFC - color for cold front symbols', 6 );
#
#  Warm front.
#
&NCAR::wmsetc( 'FRO - front type', 'WARM' );
&NCAR::wmseti( 'REV - reverse the direction of the symbols', 1 );
&NCAR::wmdrft(2,float( \@X ),float( \@Y ))      ;
&NCAR::plchhq($XP,$Y[0],':F22:Warm',$ALSIZ,0.,1.);
#
#  Warm front, aloft.
#
$Y[0] = $Y[1] - $DELY;
$Y[1] = $Y[0];

&NCAR::wmsetc( 'FRO - fornt type', 'WARM' );
&NCAR::wmseti( 'ALO - specify aloft', 1 );
&NCAR::wmseti( 'REV - reverse the direction of the symbols', 1 );
&NCAR::wmdrft(2,float( \@X ),float( \@Y ))      ;
&NCAR::plchhq($XP,$Y[0],':F22:Warm, aloft',$ALSIZ,0.,1.);
&NCAR::wmseti( 'ALO - deactivate aloft flag', 0 );
#
#  Cold front.
#
$Y[0] = $Y[1] - $DELY;
$Y[1] = $Y[0];
&NCAR::wmsetc( 'FRO - front type', 'COLD' );
&NCAR::wmseti( 'REV - reverse the direction of the symbols', 1 );
&NCAR::wmdrft(2,float( \@X ),float( \@Y ))      ;
&NCAR::plchhq($XP,$Y[0],':F22:Cold',$ALSIZ,0.,1.);
#
#  Cold front, aloft.
#
$Y[0] = $Y[1] - $DELY;
$Y[1] = $Y[0];
&NCAR::wmsetc( 'FRO - front type', 'COLD' );
&NCAR::wmseti( 'ALO - specify aloft', 1 );
&NCAR::wmseti( 'REV - reverse the direction of the symbols', 1 );
&NCAR::wmdrft(2,float( \@X ),float( \@Y ))      ;
&NCAR::plchhq($XP,$Y[0],':F22:Cold, aloft',$ALSIZ,0.,1.);
&NCAR::wmseti( 'ALO - deactivate aloft flag', 0 );
#
#  Stationary front.
#
$Y[0] = $Y[1] - $DELY;
$Y[1] = $Y[0];
&NCAR::wmsetc( 'FRO - front type', 'STATIONARY' );
&NCAR::wmseti( 'REV - reverse the direction of the symbols', 1 );
&NCAR::wmdrft(2,float( \@X ),float( \@Y ))      ;
&NCAR::plchhq($XP,$Y[0],':F22:Stationary',$ALSIZ,0.,1.);
#
#  Stationary front, aloft.
#
$Y[0] = $Y[1] - $DELY;
$Y[1] = $Y[0];
&NCAR::wmsetc( 'FRO - front type', 'STATIONARY' );
&NCAR::wmseti( 'REV - reverse the direction of the symbols', 1 );
&NCAR::wmseti( 'ALO - specify aloft', 1 );
&NCAR::wmdrft(2,float( \@X ),float( \@Y ))      ;
&NCAR::plchhq($XP,$Y[0],':F22:Stationary, aloft',$ALSIZ,0.,1.);
&NCAR::wmseti( 'ALO - deactivate aloft flag', 0 );
#
#  Occluded front.
#
$Y[0] = $Y[1] - $DELY;
$Y[1] = $Y[0];
&NCAR::wmseti( 'WFC - color for warm front symbols', 3 );
&NCAR::wmseti( 'CFC - color for cold front symbols', 3 );
&NCAR::wmsetc( 'FRO - front type', 'OCCLUDED' );
&NCAR::wmseti( 'REV - reverse the direction of the symbols', 1 );
&NCAR::wmdrft(2,float( \@X ),float( \@Y ))      ;
&NCAR::plchhq($XP,$Y[0],':F22:Occluded',$ALSIZ,0.,1.);
#
#     CALL WMDFLT
&NCAR::wmsetr( 'DWD - line widths for fronts with no symbols', 3. );
#
#  Convergence line
#
$Y[0] = $Y[1] - $DELY;
$Y[1] = $Y[0];
&NCAR::wmsetc( 'FRO - front type', 'CONVERGENCE' );
&NCAR::wmseti( 'COL - convergence lines are orange', 5 );
&NCAR::wmdrft(2,float( \@X ),float( \@Y ))      ;
&NCAR::plchhq($XP,$Y[0],':F22:Convergence line',$ALSIZ,0.,1.);
#
#  Instability line.
#
$Y[0] = $Y[1] - $DELY;
$Y[1] = $Y[0];
&NCAR::wmsetc( 'FRO - front type', 'SQUALL' );
&NCAR::wmseti( 'COL - instability line drawn in black', 1 );
&NCAR::wmdrft(2,float( \@X ),float( \@Y ))      ;
&NCAR::plchhq($XP,$Y[0],':F22:Instability line',$ALSIZ,0.,1.);
#
#  Intertropical front.
#
$Y[0] = $Y[1] - $DELY;
$Y[1] = $Y[0];
&NCAR::wmseti( 'T1C - one color for alternating dash pattern', 2 );
&NCAR::wmseti( 'T2C - second color for dash pattern', 4 );
&NCAR::wmsetc( 'FRO front type', 'TROPICAL' );
&NCAR::wmdrft(2,float( \@X ),float( \@Y ))      ;
&NCAR::plchhq($XP,$Y[0],':F22:Intertropical',$ALSIZ,0.,1.);


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/wmex01.ncgm';
