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
# Declare required dimensioned arrays.
#
my $XRA = zeroes float, 200;
my $YRA = zeroes float, 200;
my $DST = zeroes float, 220;
my $IND = zeroes long, 240;
#
# Define four different dot patterns.
#
my $ID1 = long [
   [ 1,1,0,0,0,0,1,1 ],
   [ 1,1,0,1,1,0,1,1 ],
   [ 0,0,0,1,1,0,0,0 ],
   [ 0,1,1,1,1,1,1,0 ],
   [ 0,1,1,1,1,1,1,0 ],
   [ 0,0,0,1,1,0,0,0 ],
   [ 1,1,0,1,1,0,1,1 ],
   [ 1,1,0,0,0,0,1,1 ],
];
my $ID2 = long [
   [ 0,0,0,0,0,0,0,0 ],
   [ 0,1,1,1,1,1,1,0 ],
   [ 0,1,1,1,1,1,1,0 ],
   [ 0,1,1,0,0,1,1,0 ],
   [ 0,1,1,0,0,1,1,0 ],
   [ 0,1,1,1,1,1,1,0 ],
   [ 0,1,1,1,1,1,1,0 ],
   [ 0,0,0,0,0,0,0,0 ],
];
my $ID3 = long [
   [ 0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,1,0,0,0 ],
   [ 0,0,0,1,1,1,0,0 ],
   [ 0,1,0,0,1,0,0,1 ],
   [ 0,0,1,1,1,1,1,0 ],
   [ 0,0,0,0,1,0,0,0 ],
   [ 0,0,0,1,0,1,0,0 ],
   [ 0,1,1,0,0,0,1,1 ],
];
my $ID4 = long [
   [ 0,0,0,0,0,0,0,0 ],
   [ 0,1,1,0,0,1,1,1 ],
   [ 0,1,1,0,0,1,1,0 ],
   [ 0,1,1,0,1,1,0,0 ],
   [ 0,1,1,1,1,0,0,0 ],
   [ 0,1,1,0,1,1,0,0 ],
   [ 0,1,1,0,0,1,1,0 ],
   [ 0,1,1,0,0,1,1,1 ],
];
#
# Double the size of the GKS dot.
#
&NCAR::gsmksc (2.);
#
# This code creates a single frame showing nine circles filled in
# various ways.  The DO-loop variable I says which row of circles
# we're working on (1 => top, 2 => middle, 3 => bottom).  The
# DO-loop variable J says which column of circles we're working
# on (1 => left, 2 => center, 3 => right).  The variable K gives
# the number of the circle currently being drawn and is used in
# a computed GO TO to determine which block of code is executed.
#
for my $I ( 1 .. 3 ) {
  my $YCN=(4-$I);
  for my $J ( 1 .. 3 ) {
    my $XCN=$J;
    my $K=3*($I-1)+$J;
    for my $L ( 1 .. 101 ) {
      set( $XRA, $L-1, $XCN+.48*sin(.062831853071796*$L) );
      set( $YRA, $L-1, $YCN+.48*cos(.062831853071796*$L) );
    }
#
# Draw the circle.
#
    &NCAR::set (0.,1.,0.,1.,0.,4.,0.,4.,1);
    &NCAR::curve ($XRA,$YRA,101);
#
# Jump to the proper piece of code to fill the circle.
#
    my @JUMP = (
      sub { 
        #
        # Fill the first circle with horizontal lines.
        #
        &NCAR::sfwrld ($XRA,$YRA,100,$DST,102,$IND,104);
      },
      sub { 
        #
        # Fill the second circle in the same way, but add a diamond-shaped
        # hole.
        #
        set( $XRA, 101-1, 2.00 );
        set( $YRA, 101-1, 3.24 );
        set( $XRA, 102-1, 1.76 );
        set( $YRA, 102-1, 3.00 );
        set( $XRA, 103-1, 2.00 );
        set( $YRA, 103-1, 2.76 );
        set( $XRA, 104-1, 2.24 );
        set( $YRA, 104-1, 3.00 );
        set( $XRA, 105-1, at( $XRA, 101-1 ) );
        set( $YRA, 105-1, at( $YRA, 101-1 ) );
        set( $XRA, 106-1, at( $XRA, 100-1 ) );
        set( $YRA, 106-1, at( $YRA, 100-1 ) );
        &NCAR::sfwrld ($XRA,$YRA,106,$DST,110,$IND,114);
      },
      sub { 
        #
        # Fill the third circle with lines in two different directions to
        # create a cross-hatched effect and create a more complicated hole.
        #
        set( $XRA, 101-1, at( $XRA,  40-1 ) );
        set( $YRA, 101-1, at( $YRA,  40-1 ) );
        set( $XRA, 102-1, at( $XRA,  80-1 ) );
        set( $YRA, 102-1, at( $YRA,  80-1 ) );
        set( $XRA, 103-1, at( $XRA,  20-1 ) );
        set( $YRA, 103-1, at( $YRA,  20-1 ) );
        set( $XRA, 104-1, at( $XRA,  60-1 ) );
        set( $YRA, 104-1, at( $YRA,  60-1 ) );
        set( $XRA, 105-1, at( $XRA, 100-1 ) );
        set( $YRA, 105-1, at( $YRA, 100-1 ) );
        &NCAR::sfsetr( 'SP - SPACING OF FILL LINES', .009 );
        &NCAR::sfseti( 'AN - ANGLE OF FILL LINES', 45 );
        &NCAR::sfwrld ($XRA,$YRA,105,$DST,111,$IND,117);
        &NCAR::sfseti( 'AN - ANGLE OF FILL LINES', 135 );
        &NCAR::sfnorm ($XRA,$YRA,105,$DST,111,$IND,117);
      },
      sub { 
        #
        # Fill the fourth circle with the default dot pattern, increasing the
        # inter-dot spacing considerably.
        #
        &NCAR::sfsetr ('SP - SPACING OF FILL LINES',.005);
        &NCAR::sfseti( 'AN - ANGLE OF FILL LINES', 0 );
        &NCAR::sfseti( 'DO - DOT-FILL FLAG', 1 );
        &NCAR::sfwrld ($XRA,$YRA,100,$DST,102,$IND,104);
      },
      sub { 
        #
        # Fill the fifth circle with a combination of lines and dots.
        #
        &NCAR::sfsetr ('SP - SPACING OF FILL LINES',.012);
        &NCAR::sfseti( 'DO - DOT-FILL FLAG', 0 );
        &NCAR::sfwrld ($XRA,$YRA,100,$DST,102,$IND,104);
        &NCAR::sfsetr( 'SP - SPACING OF FILL LINES', .006 );
        &NCAR::sfseti( 'DO - DOT-FILL FLAG', 1 );
        &NCAR::sfnorm ($XRA,$YRA,100,$DST,102,$IND,104);
      },
      sub { 
        #
        # Fill the sixth circle with a specified dot pattern.
        #
        &NCAR::sfsetr ('SP - SPACING OF FILL LINES',.004);
        &NCAR::sfsetp ($ID1);
        &NCAR::sfwrld ($XRA,$YRA,100,$DST,102,$IND,104);
      },
      sub { 
        #
        # Fill the seventh circle with a different dot pattern, tilted at an
        # angle.
        #
        &NCAR::sfseti ('AN - ANGLE OF FILL LINES',45);
        &NCAR::sfsetp ($ID2);
        &NCAR::sfwrld ($XRA,$YRA,100,$DST,102,$IND,104);
      },
      sub { 
        #
        # Fill the eighth circle with a different dot pattern, using characters.
        #
        &NCAR::gschh  (.004);
        &NCAR::sfsetr( 'SP - SPACING OF FILL LINES', .006 );
        &NCAR::sfseti( 'AN - ANGLE OF FILL LINES', 0 );
        &NCAR::sfsetc( 'CH - CHARACTER SPECIFIER', 'O' );
        &NCAR::sfsetp ($ID3);
        &NCAR::sfwrld ($XRA,$YRA,100,$DST,102,$IND,104);
      },
      sub {
        #
        # Fill the last circle with K's, both large and small.
        #
        &NCAR::gschh  (.008);
        &NCAR::sfsetr( 'SP - SPACING OF FILL LINES', .012 );
        &NCAR::sfsetc( 'CH - CHARACTER SPECIFIER', 'K' );
        &NCAR::sfsetp ($ID4);
        &NCAR::sfwrld ($XRA,$YRA,100,$DST,102,$IND,104);
      },
    );
    $JUMP[ $K-1 ]->();
  }
#
}
&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/sfex01.ncgm';
