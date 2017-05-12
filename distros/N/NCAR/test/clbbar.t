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

      
my $INDEX  = long [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 ];

my @LABELS = (
       'White', 'Orchid', 'Red', 'OrangeRed', 'Orange',
       'Gold', 'Yellow', 'GreenYellow', 'Chartreuse',       
       'Green', 'Celeste', 'Aqua','DeepSkyBlue','RoyalBlue',
       'SlateBlue', 'DarkViolet', 'Lavender', 'Grey' 
);
#
&COLOR (1);
&NCAR::gsfais(1);
&NCAR::lblbar(1,0.,1.,0.,1.,18,.5,1.,$INDEX,1,\@LABELS,18,1);
#
sub COLOR {
#
#   *** BACKGROUND COLOR ***
# Black
#
&NCAR::gscr(1,0,0.,0.,0.);
#
#   *** FORGROUND COLORS ***
# White
#
&NCAR::gscr(1,  1, 1.0, 1.0, 1.0);
#
# Orchid
#
&NCAR::gscr(1,  2, 0.85, 0.45, 0.8);
#
# Red
#
&NCAR::gscr(1,  3, 0.9, 0.25, 0.0);
#
# OrangeRed
#
&NCAR::gscr(1,  4, 1.0, 0.0, 0.2);
#
# Orange
#
&NCAR::gscr(1,  5, 1.0, 0.65, 0.0);
#
# Gold
#
&NCAR::gscr(1,  6, 1.0, 0.85, 0.0);
#
# Yellow
#
&NCAR::gscr(1,  7, 1.0, 1.0, 0.0);
#
# GreenYellow
#
&NCAR::gscr(1,  8, 0.7, 1.0, 0.2);
#
# Chartreuse
#
&NCAR::gscr(1,  9, 0.5, 1.0, 0.0);
#
# Green
#
&NCAR::gscr(1, 10, 0.2, 0.8, 0.2);
#
# Celeste
#
&NCAR::gscr(1, 11, 0.2, 1.0, 0.5);
#
# Aqua
#
&NCAR::gscr(1, 12, 0.0, 0.9, 1.0);
#
# DeepSkyBlue
#
&NCAR::gscr(1, 13, 0.0, 0.75, 1.0);
#
# RoyalBlue
#
&NCAR::gscr(1, 14, 0.25, 0.45, 0.95);
#
# SlateBlue
#
&NCAR::gscr(1, 15, 0.4, 0.35, 0.8);
#
# DarkViolet
#
&NCAR::gscr(1, 16, 0.6, 0.0, 0.8);
#
# Lavender
#
&NCAR::gscr(1, 17, 0.8, 0.8, 1.0);
#
# Gray
#
&NCAR::gscr(1, 18, 0.5, 0.5, 0.5);
#
# Done.
#
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/clbbar.ncgm';
