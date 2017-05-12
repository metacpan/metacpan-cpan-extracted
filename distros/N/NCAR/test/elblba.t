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
# Initialize the values in the aspect-source-flag array.
#
my $IASF = long [ ( 1 ) x 13 ];
#
# Define the list of indices required by the label-bar routine.
#
my $LND1 = long [ 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20 ];
my $LND2 = long [ 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 ];
my @LND3 = map { long( $_ ) } ( 
             [ 12, 13, 14, 15 ], 
             [  8,  9, 10, 11 ], 
             [  4,  5,  6,  7 ], 
             [  0,  1,  2,  3 ] 
           );
#
# Define labels for various bars.
#
my @LLB1 = (
      '0 to 5:H2Q', '5 to 10:H1Q','10 to 15:H1Q',
    '15 to 20:H1Q','20 to 25:H1Q','25 to 30:H1Q',
    '30 to 35:H1Q','35 to 40:H1Q','40 to 45:H1Q',
    '45 to 50:H1Q','50 to 55:H1Q','55 to 60:H1Q',
    '60 to 65:H1Q','65 to 70:H1Q','70 to 75:H1Q',
    '75 to 80:H1Q','80 to 85:H1Q','85 to 90:H1Q',
    '90 to 95:H1Q','95 to 100' 
);
#
my @LLB2 = (
     '-2000 feet',' Sea level',' 2000 feet',
     ' 4000 feet',' 6000 feet',' 8000 feet',
     '10000 feet','12000 feet','14000 feet',
     '16000 feet','18000 feet','20000 feet',
     '22000 feet','24000 feet','26000 feet',
     '28000 feet','30000 feet'
);
#
my @LLB3 = ( 'M','N','O','P','I','J','K','L','E','F','G','H','A','B','C','D' );
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Set all the GKS aspect source flags to "individual".
#
&NCAR::gsasf ($IASF);
#
# Force solid fill.
#
&NCAR::gsfais (1);
#
# Define color indices.
#
&DFCLRS();
#
# Force PLOTCHAR to use constant spacing of characters.
#
&NCAR::pcsetr ('CS - CONSTANT SPACING',1.25);
#
# Set some parameter values.
#
&NCAR::lbsetr ('WBL - WIDTH OF BOX LINES',4.);
&NCAR::lbsetr ('WFL - WIDTH OF FILL LINES',2.);
&NCAR::lbsetr ('WLB - WIDTH OF LABEL LINES',2.);
#
# Put the first label bar vertically along the left edge of the plotter
# frame.  Use patterns.
#
&NCAR::sfseti ('ANGLE OF FILL LINES',15);
&NCAR::sfseti ('TYPE OF FILL',-4);
&NCAR::lblbar (1,.05,.30,.05,.95,20,.3333,1.,$LND1,0,\@LLB1,20,2);
#
# Put the second label bar vertically along the right edge.  Use solid
# color fill.
#
&NCAR::sfseti ('TYPE OF FILL',0);
&NCAR::lblbar (1,.70,.95,.05,.95,16,.3333,1.,$LND2,0,\@LLB2,17,1);
#
# The remaining label bars are arranged horizontally in such a way as
# to form a rectangular key for color indices 1 through 12.  The
# default version of LBFILL is used.
#
&NCAR::lblbar (0,.35,.65,.05,.20,4,.5,.5, $LND3[0],1,[ @LLB3[ 0.. 3] ],4,1);
&NCAR::lblbar (0,.35,.65,.20,.35,4,.5,.5, $LND3[1],1,[ @LLB3[ 4.. 7] ],4,1);
&NCAR::lblbar (0,.35,.65,.35,.50,4,.5,.5, $LND3[2],1,[ @LLB3[ 8..11] ],4,1);
&NCAR::lblbar (0,.35,.65,.50,.65,4,.5,.5, $LND3[3],1,[ @LLB3[12..15] ],4,1);
#
# Put a title on the plot.  We must first call SET to define the ranges
# of the X and Y coordinates to be used.  The constant spacing feature
# is turned off so that the title will look normal.
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::pcsetr ('CS - CONSTANT SPACING',0.);
&NCAR::plchhq (.5,.90,'THREE',.025,0.,0.);
&NCAR::plchhq (.5,.85,'LABELBAR',.025,0.,0.);
&NCAR::plchhq (.5,.80,'EXAMPLES',.025,0.,0.);

sub DFCLRS {
  my @RGBV = (
    [ 1.00 , 1.00 , 1.00 ],
    [ 0.70 , 0.70 , 0.70 ],
    [ 0.75 , 0.50 , 1.00 ],
    [ 0.50 , 0.00 , 1.00 ],
    [ 0.00 , 0.00 , 1.00 ],
    [ 0.00 , 0.50 , 1.00 ],
    [ 0.00 , 1.00 , 1.00 ],
    [ 0.00 , 1.00 , 0.60 ],
    [ 0.00 , 1.00 , 0.00 ],
    [ 0.70 , 1.00 , 0.00 ],
    [ 1.00 , 1.00 , 0.00 ],
    [ 1.00 , 0.75 , 0.00 ],
    [ 1.00 , 0.38 , 0.38 ],
    [ 1.00 , 0.00 , 0.38 ],
    [ 1.00 , 0.00 , 0.00 ],
  );
#
# Define 16 different color indices, for indices 0 through 15.  The
# color corresponding to index 0 is black and the color corresponding
# to index 1 is white.
#
  &NCAR::gscr (1,0,0.,0.,0.);
#
  for my $I ( 1 .. 15 ) {
    &NCAR::gscr (1,$I,@{ $RGBV[$I-1] });
  }
#
# Done.
#
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/elblba.ncgm';
