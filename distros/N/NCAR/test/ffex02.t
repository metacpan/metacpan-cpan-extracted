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

#
sub RDDATA {
  my ( $U,$V,$P,$M,$N ) = @_;
#
# Read the data arrays from the standard input 
#
  my @D;
  open FILE, "<data/ffex02.dat";
  { local $/ = undef; ( my $D = <FILE> ) =~ s/^\s*//o; @D = split( m/\s*(?:,|\s)\s*/o, $D ); }
  close FILE;
  for my $I ( 1 .. $M ) {
    for my $J ( 1 .. $N ) {
       set( $U, $J-1, $I-1, shift( @D ) );
    }
  }
  for my $I ( 1 .. $M ) {
    for my $J ( 1 .. $N ) {
       set( $V, $J-1, $I-1, shift( @D ) );
    }
  }
  for my $I ( 1 .. $M ) {
    for my $J ( 1 .. $N ) {
       set( $P, $J-1, $I-1, shift( @D ) );
    }
  }
}


my $IDM;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
# This program requires the input data file 'ffex02.dat'
# It reads the data from standard input, e.g.: ffex02 < ffex02.dat
#
my ( $MSIZE, $NSIZE, $NCLRS ) = ( 36, 33, 14 );
#
my $U = zeroes float, $NSIZE, $MSIZE;
my $V = zeroes float, $NSIZE, $MSIZE;
my $P = zeroes float, $NSIZE, $MSIZE;
#
# Define a set of RGB color triples
#
      my @RGBV = (
        [       0.0,       1.0,      1.0 ],
        [ 0.0745098,   0.92549,  0.92549 ],
        [  0.152941,  0.847059, 0.847059 ],
        [  0.231373,  0.768627, 0.768627 ],
        [  0.305882,  0.694118, 0.694118 ],
        [  0.384314,  0.615686, 0.615686 ],
        [  0.462745,  0.537255, 0.537255 ],
        [  0.537255,  0.462745, 0.462745 ],
        [  0.615686,  0.384314, 0.384314 ],
        [  0.694118,  0.305882, 0.305882 ],
        [  0.768627,  0.231373,  0.23137 ],
        [  0.847059,  0.152941, 0.152941 ],
        [   0.92549, 0.0745098, 0.074509 ],
        [       1.0,       0.0,      0.0 ],
       );
#
# Read the input array data
#

&RDDATA($U,$V,$P,$MSIZE,$NSIZE);

#
# Set up the EZMAP projection
#


&NCAR::mapset('CO',
              float( [   60.0, 0 ] ),
	      float( [ -120.0, 0 ] ),
	      float( [   23.0, 0 ] ),
	      float( [  -60.0, 0 ] )
	      );
&NCAR::maproj('LC',0.0,-75.0,45.0);
&NCAR::mapint;
#
# Tell Vectors to use the mapping established by EZMAP
#
&NCAR::vvseti( 'MAP -- Mapping Flag', 1 );
&NCAR::vvseti( 'SET -- Set Call Flag', 0 );
#
# Set up data coordinate boundaries and special value processing 
# appropriately for the dataset 
#
&NCAR::vvsetr( 'XC1 -- Lower X Bound', -140.0 );
&NCAR::vvsetr( 'XCM -- Upper X Bound', -52.5 );
&NCAR::vvsetr( 'YC1 -- Lower X Bound', 20.0 );
&NCAR::vvsetr( 'YCN -- Upper Y Bound', 60.0 );
#
&NCAR::vvseti( 'SVF -- Special Values Flag', 3 );
&NCAR::vvsetr( 'USV -- U Special Value', -9999.0 );
&NCAR::vvsetr( 'VSV -- V Special Value', -9999.0 );
&NCAR::vvsetr( 'PSV - P Special Value', -9999.0 );
&NCAR::vvseti( 'SPC - P Special Color', 1 );
#
# Turn on statistics reporting
#
&NCAR::vvseti( 'VST -- Vector Statistics', 1 );
#

for my $IFRMNO ( 1 .. 4 ) {
#
# Draw the map with a grid
#

  &NCAR::maplot;
  &NCAR::mapgrd;
#
# Set up color processing
#
  if( $IFRMNO == 4 ) {
&NCAR::vvseti( 'CTV -- Color Thresholds Value', 2 );
&NCAR::vvseti( 'NLV -- Number Of Levels', $NCLRS );
    for my $I ( 1 .. $NCLRS ) {
      my $ICLRIX=2+($I-1)*200/$NCLRS;
      &NCAR::gscr(1,$ICLRIX,@{ $RGBV[$I-1] });
&NCAR::vvseti( 'PAI -- Parameter Array Index', $I );
&NCAR::vvseti( 'CLR -- GKS Color Index', $ICLRIX );
    }
  }
#
# Initialize Vectors
#
  if( $IFRMNO > 1 ) {
    &NCAR::vvinit ($U,$MSIZE,$V,$MSIZE,$P,$MSIZE,$MSIZE,$NSIZE,float( [ 0 ] ),$IDM);
  }
#
# Adjust vector rendering options
#
  if( $IFRMNO == 3 ) {
&NCAR::vvsetr( 'AMN -- Arrow Minimum Size', 0.007 );
&NCAR::vvsetr( 'LWD -- Vector Line Width', 1.75 );
&NCAR::vvgetr( 'VMN -- Minimum Vector', my $VMN );
&NCAR::vvgetr( 'VMX -- Maximum Vector', my $VMX );
&NCAR::vvsetr( 'VLC -- Vector Low Cutoff', $VMN+0.125*($VMX-$VMN) );
&NCAR::vvgetr( 'DMX -- Device Maximum Vector Length', my $DMX );
    &NCAR::getset( my ( $VL,$VR,$VB,$VT,$UL,$UR,$UB,$UT,$LL) );
&NCAR::vvsetr( 'VRL - Vector Realized Length', 1.8*$DMX/($VR-$VL) );
&NCAR::vvsetr( 'VFR -- Vector Fractional Minimum', 0.33 );
  }
#
# Draw the vector field plot
#
  if( $IFRMNO > 1 ) {
     &NCAR::vvectr ($U,$V,$P,long([]),$IDM,float([]));
  }
#
# Draw a perimeter boundary and eject the frame
#
  &NCAR::perim(1,0,1,0);
  &NCAR::frame;
#
}
&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/ffex02.ncgm';
