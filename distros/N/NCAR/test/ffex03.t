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

my $IDM;
#
# This program requires the input data file 'ffex02.dat'
# It reads the data from standard input, e.g.: ffex03 < ffex02.dat
#
my ( $MSIZE, $NSIZE ) = ( 36, 33 );
my $ISTWKL = 2*$MSIZE*$NSIZE;
#
my $U = zeroes float, $NSIZE, $MSIZE;
my $V = zeroes float, $NSIZE, $MSIZE;
my $P = zeroes float, $NSIZE, $MSIZE;
my $WRK = zeroes float, $ISTWKL;
#
# Conpack work space and Areas area map
#
my ( $ICPIWL, $ICPRWL, $IAREAL ) = ( 1000, 5000, 20000 );
my $RWRK = zeroes float, $ICPRWL;
my $IWRK = zeroes long, $ICPIWL;
my $IAM = zeroes long, $IAREAL;
#
# Arrays for drawing masked grids
#
my ( $MCRA, $NOGI ) = ( 64, 64 );
my $XCRA = zeroes float, $MCRA;
my $YCRA = zeroes float, $MCRA;
my $IAAI = zeroes long, $NOGI;
my $IAGI = zeroes long, $NOGI;
#
# External subroutine declarations
#
#     EXTERNAL DRAWCL;
#     EXTERNAL STUMSL;
#
# Define a set of RGB color triples
#
my $NCLRS = 3;
my @ICLR;
#
my @RGBV = (
      [ 1.0,0.0,0.0, ],
      [ 0.0,0.0,1.0, ],
      [ 0.5,0.5,0.5  ],
);
#
# Read the input array data
#
&RDDATA($U,$V,$P,$MSIZE,$NSIZE);
#
# Set up colors for fixed table grayscale and color workstations
# Colors allocated as follows: 1, map outline; 2, contour lines;
#  3, grid lines; (streamlines and labels use default black or white.
#
for my $I ( 1 .. $NCLRS ) {
  my $ICLRIX=64+($I-1)*196/$NCLRS;
  &NCAR::gscr(1,$ICLRIX,@{ $RGBV[$I-1] });
  $ICLR[$I-1] = $ICLRIX;
}
#
# Set up the EZMAP transformation
#
&NCAR::mapset('CO',
               float( [   60.0, 0 ] ),
	       float( [ -120.0, 0 ] ),
	       float( [   23.0, 0 ] ),
	       float( [  -60.0, 0 ] )
	       );
&NCAR::maproj('LC',0.0,-75.0,45.0);
&NCAR::mapint;
&NCAR::mapsti('C5 - Continental Outline Color',$ICLR[0]);
#
# Tell Streamlines to use the mapping established by EZMAP
#
&NCAR::stseti( 'MAP -- Mapping Flag', 1 );
&NCAR::stseti( 'SET -- Set Call Flag', 0 );
#
# Set up data coordinate boundaries and special value processing 
# appropriately for the dataset 
#
&NCAR::stsetr( 'XC1 -- Lower X Bound', -140.0 );
&NCAR::stsetr( 'XCM -- Upper X Bound', -52.5 );
&NCAR::stsetr( 'YC1 -- Lower X Bound', 20.0 );
&NCAR::stsetr( 'YCN -- Upper Y Bound', 60.0 );
#
&NCAR::stseti( 'SVF -- Special Values Flag', 1 );
&NCAR::stsetr( 'USV -- U Special Value', -9999.0 );
&NCAR::stsetr( 'VSV -- V Special Value', -9999.0 );
#
# Do the equivalent Conpack setup; note that the special value
# parameter works a bit differently, and also Conpack requires
# an Out of Range value to be set whenever the data grid extends
# outside the map boundaries. The standard value for the default
# version of CPMPXY is 1.0E12
#
&NCAR::cpseti( 'MAP -- Mapping Flag', 1 );
&NCAR::cpseti( 'SET -- Set Call Flag', 0 );
&NCAR::cpsetr( 'XC1 -- Lower X Bound', -140.0 );
&NCAR::cpsetr( 'XCM -- Upper X Bound', -52.5 );
&NCAR::cpsetr( 'YC1 -- Lower X Bound', 20.0 );
&NCAR::cpsetr( 'YCN -- Upper Y Bound', 60.0 );
&NCAR::cpsetr( 'SPV -- Special Value', -9999.0 );
&NCAR::cpsetr( 'ORV -- Out of Range Value', 1.0E12 );
#
# Set Conpack graphics text parameters
#
&SETCGT;
#
# Draw the continental outline using a wide line
#
&NCAR::gslwsc(4.0);
&NCAR::maplot;
&NCAR::gslwsc(1.0);
#
# Initialize the drawing of the contour plot, and tell Conpack
# to pick contour levels.
#
&NCAR::cprect ($P,$MSIZE,$MSIZE,$NSIZE,$RWRK,$ICPRWL,$IWRK,$ICPIWL);
&NCAR::cppkcl ($P,$RWRK,$IWRK);
#
# Set up contour line attributes
#
&NCAR::cpgeti( 'NCL - Number Of Contour Levels', my $NCLV );
&SETCLA($NCLV);
#
# Initialize the area map, add the Conpack labels to the area map,
# then draw the labels, draw masked contour lines, and finally
# draw the masked map grids. Note that there is currently no way
# to draw a masked continental outline.
#
&NCAR::arinam ($IAM,$IAREAL);
&NCAR::cplbam ($P,$RWRK,$IWRK,$IAM);
&NCAR::cplbdr ($P,$RWRK,$IWRK);
&NCAR::cpcldm ($P,$RWRK,$IWRK,$IAM,\&DRAWCL);
&NCAR::mapsti('C2 - Grid',$ICLR[2]);
&NCAR::gsplci($ICLR[2]);
&NCAR::mapgrm ($IAM,$XCRA,$YCRA,$MCRA,$IAAI,$IAGI,$NOGI,\&DRAWCL);
&NCAR::gsplci(1);
#
# Adjust streamline rendering options and turn on statistics
#
&NCAR::stsetr( 'LWD -- Streamline Line Width', 1.75 );
&NCAR::stseti( 'MSK -- Streamline Masking', 1 );
&NCAR::stsetr( 'SSP -- Stream Spacing', 0.012 );
&NCAR::stsetr( 'DFM -- Differential Magnitude', 0.012 );
&NCAR::stseti( 'SST -- Streamline Statistics', 1 );
#
# Initialize Streamlines
#
&NCAR::stinit ($U,$MSIZE,$V,$MSIZE,float( [ 0 ] ),$IDM,$MSIZE,$NSIZE,$WRK,$ISTWKL);
#
# Draw the streamline field plot
#
&NCAR::stream ($U,$V,float([]),$IAM,\&STUMSL,$WRK);
#
# Draw a perimeter boundary and eject the frame
#
&NCAR::perim(1,0,1,0);
#
# =====================================================================
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
#
# =====================================================================
#
sub DRAWCL {
  my ( $XCS,$YCS,$NCS,$IAI,$IAG,$NAI ) = @_;
#
# Routine for masked drawing of contour and grid lines
#
# This version of DRAWCL draws the polyline defined by the points
# ((XCS(I),YCS(I)),I=1,NCS) if and only if none of the area identifiers
# for the area containing the polyline are negative.  The dash package
# routine CURVED is called to do the drawing.
#
#
# Turn on drawing.
#
  my $IDR=1;
#
# If any area identifier is negative, turn off drawing.
#
  for my $I ( 1 .. $NAI ) {
    if( at( $IAI, $I-1 ) < 0 ) { $IDR = 0; }
  }
#
# If drawing is turned on, draw the polyline.
#
  if( $IDR != 0 ) { &NCAR::curved($XCS,$YCS,$NCS); }
#
# Done.
#
}#
# =====================================================================
#
sub SETCGT {
#
# Sets Conpack Graphics Text Parameters
#
&NCAR::cpseti( 'LLP - LINE LABEL POSITIONING', 3 );
&NCAR::cpseti( 'RWC - REAL WORKSPACE FOR CONTOURS', 200 );
&NCAR::cpseti( 'HLB - HIGH/LOW LABEL BOX FLAG', 1 );
&NCAR::cpseti( 'LLB - HIGH/LOW LABEL BOX FLAG', 0 );
&NCAR::cpsetc( 'ILT - INFORMATION LABEL TEXT', ' ' );
&NCAR::cpseti( 'HLO - HIGH/LOW LABEL OVERLAP FLAG', 11 );
&NCAR::cpsetr( 'CWM - CHARACTER WIDTH MULTIPLIER', 1.25 );
#
}
#
# =====================================================================
#
sub SETCLA {
  my ($NCLV) = @_;
#
# Sets Contour Line Attributes
#
  my $NCLRS=3;
#
  for my $ICLV ( 1 .. $NCLV ) {
#
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', $ICLV );
&NCAR::cpgeti( 'CLU - CONTOUR LEVEL USE FLAG', my $ICLU );
&NCAR::cpseti( 'CLL - CONTOUR-LINE LINE WIDTH', 3 );
&NCAR::cpseti( 'CLC - CONTOUR-LINE COLOR', $ICLR[1] );
    if( $ICLU == 3 ) {
&NCAR::cpseti( 'CLL - CONTOUR-LINE LINE WIDTH', 6 );
    }
#
  }
#
# 'Special' contour lines - grid, special values, and out of range
# boundaries
#
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', -1 );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE FLAG', 1 );
&NCAR::cpsetr( 'CLL - CONTOUR LEVEL LINE WIDTH', 2. );
&NCAR::cpseti( 'CLC - CONTOUR LEVEL LINE COLOR', $ICLR[2] );
#
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', -2 );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE FLAG', 1 );
&NCAR::cpsetr( 'CLL - CONTOUR LEVEL LINE WIDTH', 2. );
&NCAR::cpseti( 'CLC - CONTOUR LEVEL LINE COLOR', $ICLR[2] );
#
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', -3 );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE FLAG', 1 );
&NCAR::cpsetr( 'CLL - CONTOUR LEVEL LINE WIDTH', 2. );
&NCAR::cpseti( 'CLC - CONTOUR LEVEL LINE COLOR', $ICLR[2] );
#
}

sub STUMSL {
  my ($XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
  for my $I ( 1 .. $NAI ) {
    return if( at( $IAI, $I-1 ) < 0 );
  }
   &NCAR::curve($XCS,$YCS,$NCS);
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/ffex03.ncgm';
