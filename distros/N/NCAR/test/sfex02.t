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
my $XCS = zeroes float, 101;
my $YCS = zeroes float, 101;
my $XRA = zeroes float, 100;
my $YRA = zeroes float, 100;
my $DST = zeroes float, 102;
my $IND = zeroes long, 104;
#
# Declare an array to hold the GKS "aspect source flags".
#
my $IAS = long [ ( 1 ) x 13 ];
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Set all the GKS aspect source flags to "individual".
#
&NCAR::gsasf ($IAS);
#
# Force solid fill.
#
&NCAR::gsfais (1);
#
# Define color indices.
#
&DFCLRS();
#
# Define the window and viewport to make it easy to do seven rows
# containing sixteen ovals apiece.
#
&NCAR::set (0.,1.,0.,1.,-1.,16.5,-.5,7.5,1);
#
# For each of the possible values of the internal parameter 'TY', fill
# a set of circles, one for each of sixteen values of ICI (0-15).
#
for my $ITY ( -4 .. 2 ) {
#
  my $YCN=(3-$ITY);
#
  my $LBL = sprintf( '%2d', $ITY );
  &NCAR::plchhq (&NCAR::cfux(&NCAR::cfux(.5)-.006),$YCN,$LBL,.012,0.,1.);
#
&NCAR::sfseti( 'TYPE OF FILL', $ITY );
#
  for my $ICI ( 0 .. 15 ) {
#
    my $XCN=($ICI+1);
#
    for my $L ( 1 .. 101 ) {
       set( $XCS, $L-1, $XCN+.48*sin(.062831853071796*$L) );
       set( $YCS, $L-1, $YCN+.48*cos(.062831853071796*$L) );
       if( $L < 101 ) {
          set( $XRA, $L-1, at( $XCS, $L-1 ) );
          set( $YRA, $L-1, at( $YCS, $L-1 ) );
       }
    }
#
    &NCAR::sfsgfa ($XRA,$YRA,100,$DST,102,$IND,104,$ICI);
#
    &NCAR::curve ($XCS,$YCS,101);
#
  }
#
}
#
# Finish the labelling.
#
&NCAR::plchhq (&NCAR::cfux(&NCAR::cfux(.5)-.060),4.,'"TYPE OF FILL"',.012,90.,0.);
#
for my $ICI ( 0 .. 15 ) {
  my $XCN=($ICI+1);
  if( $ICI < 10 ) {
    my $LBL = sprintf( '%1d', $ICI );
    &NCAR::plchhq ($XCN,&NCAR::cfuy(&NCAR::cfuy(.5)-.024),substr( $LBL, 0, 1 ),.012,0.,0.);
  } else {
    my $LBL = sprintf( '%2d', $ICI );
    &NCAR::plchhq ($XCN,&NCAR::cfuy(&NCAR::cfuy(.5)-.024),substr( $LBL, 0, 2 ),.012,0.,0.);
  }
}
#
&NCAR::plchhq (8.5,&NCAR::cfuy(&NCAR::cfuy(.5)-.060),'"COLOR INDEX"',.012,0.,0.);

sub DFCLRS {
#
# Define a set of RGB color triples for colors 1 through 15.
#
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

rename 'gmeta', 'ncgm/sfex02.ncgm';
