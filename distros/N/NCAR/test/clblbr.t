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
my @LAB1 = ( 
      '.','here','go','can',':G:font','any','in',
      'number','or','word','Any'
);
my @LAB2 = ( 
      '.','boxes','between','lines','the','or','boxes',
      'either','match','can','labels','that','Notice'
);
my $IFILL1 = long [ 11,10,9,8,7,6,5,4,3,2,1 ];
my $IFILL2 = long [ 3,4,5,6,7,8,9,10,2,11,12,13,14,15 ];
#
# Set up color table
#
&COLOR();
#
# Set color fill to be solid
#
&NCAR::gsfais(1);
#
# Draw two vertical label bars.
#
&NCAR::sfsetr('AN',35.);
&NCAR::sfseti('TY',-4);
&NCAR::lblbar(1,.05,.45,.05,.95,11,.3,1.,$IFILL1,0,\@LAB1,11,1);
&NCAR::sfseti('TY',0);
&NCAR::lblbar(1,.55,.95,.05,.95,14,.3,1.,$IFILL2,1,\@LAB2,13,2);

sub COLOR {
#
# BACKGROUND COLOR
# BLACK
#
&NCAR::gscr(1,0,0.,0.,0.);
#
#     FORGROUND COLORS
# White
#
&NCAR::gscr(1,  1, 1.0, 1.0, 1.0);
#
# Aqua
#
&NCAR::gscr(1,  2, 0.0, 0.9, 1.0);
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
# Yellow
#
&NCAR::gscr(1,  6, 1.0, 1.0, 0.0);
#
# GreenYellow
#
&NCAR::gscr(1,  7, 0.7, 1.0, 0.2);
#
# Chartreuse
#
&NCAR::gscr(1,  8, 0.5, 1.0, 0.0);
#
# Celeste
#
&NCAR::gscr(1,  9, 0.2, 1.0, 0.5);
#
# Green
#
&NCAR::gscr(1, 10, 0.2, 0.8, 0.2);
#
# DeepSkyBlue
#
&NCAR::gscr(1, 11, 0.0, 0.75, 1.0);
#
# RoyalBlue
#
&NCAR::gscr(1, 12, 0.25, 0.45, 0.95);
#
# SlateBlue
#
&NCAR::gscr(1, 13, 0.4, 0.35, 0.8);
#
# DarkViolet
#
&NCAR::gscr(1, 14, 0.6, 0.0, 0.8);
#
# Orchid
#
&NCAR::gscr(1, 15, 0.85, 0.45, 0.8);
#
# Lavender
#
&NCAR::gscr(1, 16, 0.8, 0.8, 1.0);
#
# Gray
#
&NCAR::gscr(1, 17, 0.7, 0.7, 0.7);
#
# Done.
#
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/clblbr.ncgm';
