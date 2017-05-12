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


my ( $X1, $X2, $X3 ) = ( 0.18,  0.46,  0.74 )       ;
#
&NCAR::gscr(1,0,1.,1.,1.);
&NCAR::gscr(1,1,0.,0.,0.);
&NCAR::gscr(1,2,.4,0.,.4);
#
#  Wind barbs at various angles using differing attributes.
#
&NCAR::plchhq(0.5,0.94,':F26:Wind barb examples',.04,0.,0.);
#
#  Set barb color and size.
#
&NCAR::wmseti( 'COL', 2 );
&NCAR::wmsetr( 'WBS', 0.25 );
#
#  Draw first barb (all defaults with a wind speed of 71 knots).
#
&NCAR::wmbarb($X1,.5,26.,71.);
#
#  Second barb - change the angle of the tick marks and the spacing 
#  between ticks and draw another barb.
#
&NCAR::wmgetr( 'WBA', my $WBAO );
&NCAR::wmgetr( 'WBD', my $WBDO );
&NCAR::wmsetr( 'WBA', 42. );
&NCAR::wmsetr( 'WBD', .17 );
&NCAR::wmbarb($X2,.5,0.,75.);
&NCAR::wmsetr( 'WBA', $WBAO );
&NCAR::wmsetr( 'WBD', $WBDO );
#
#  Third barb - draw a sky cover symbol at base of the barb (these 
#  are drawn automatically when using WMSTNM to plot station model data).
#
&NCAR::wmgetr( 'WBS', my $WBS );
&NCAR::wmgetr( 'WBC', my $WBC );
&NCAR::wmseti( 'WBF', 1 );
&NCAR::wmbarb($X3,.5,-26.,71.);
&NCAR::ngwsym('N',0,$X3,.5,$WBS*$WBC,2,0);
#
#  Fourth barb - change the size of the barb and the size of the sky 
#  cover symbol.
# 
&NCAR::wmsetr( 'WBS', 0.20 );
&NCAR::wmsetr( 'WBC', 0.15 );
&NCAR::wmbarb($X1+0.1,0.1,-26.,71.);
&NCAR::ngwsym('N',0,$X1+0.1,.1,0.20*0.15,2,0);
#
#  Fifth barb - reset original values for parameters, change wind speed
#               to 45 knots.
#
&NCAR::wmsetr( 'WBS', $WBS );
&NCAR::wmsetr( 'WBC', $WBC );
&NCAR::wmseti( 'WBF', 0 );
&NCAR::wmbarb($X2,.1,0.,45.);
#
#  Sixth barb - change the tick lengths.
#
&NCAR::wmsetr( 'WBT', .6 );
&NCAR::wmbarb($X3-0.1,.1,15.4,42.2);


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/wmex10.ncgm';
