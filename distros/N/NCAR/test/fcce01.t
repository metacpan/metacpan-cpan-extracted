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


my $X1 = float [ 0.15, 0.35, 0.35, 0.15, 0.15 ];
my $X2 = float [ 0.65, 0.85, 0.85, 0.65, 0.65 ];
my $Y  = float [ 0.45, 0.45, 0.65, 0.65, 0.45 ];
#
#  Set up the color table for the CGM workstation:
#    
#    Index  Color
#    -----  -----
#      0    Black (background color)
#      1    White (foreground color)
#      2    Red
#      3    Green
#      4    Yellow
#      5    Cyan
#
&NCAR::gscr(1, 0, 0.0, 0.0, 0.0);
&NCAR::gscr(1, 1, 1.0, 1.0, 1.0);
&NCAR::gscr(1, 2, 1.0, 0.0, 0.0);
&NCAR::gscr(1, 3, 0.0, 1.0, 0.0);
&NCAR::gscr(1, 4, 1.0, 1.0, 0.0);
&NCAR::gscr(1, 5, 0.0, 1.0, 1.0);
#
#  Draw a green rectangle.
#
&NCAR::gsplci(3);
&NCAR::gpl(5,$X1,$Y);
#
#  Draw an asterisk scaled by 4. in the foreground color.
#
&NCAR::gsmksc(4.);
&NCAR::gpm(1,.5,.25);
#
#  Draw a text string in yellow.
#
&NCAR::gstxci(4);
&NCAR::gtx(0.5,0.5,'Text');
#
#  Draw a filled rectangle in cyan.
#
&NCAR::gsfaci(5);
&NCAR::gsfais(1);
&NCAR::gfa(5,$X2,$Y);
#
#  Draw a red asterisk.
#
&NCAR::gspmci(2);
&NCAR::gpm(1,.5,.75);




&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/fcce01.ncgm';
