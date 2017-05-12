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

my $IDM;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );
#
# This program requires the input data file 'ffex05.dat'
# It reads the data from standard input, e.g.: ffex05 < ffex05.dat
#
my ( $MSIZE, $NSIZE ) = ( 73, 73 );
#
my $U = zeroes float, $NSIZE, $MSIZE;
my $V = zeroes float, $NSIZE, $MSIZE;
my $P = zeroes float, $NSIZE, $MSIZE;
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
#     EXTERNAL VVUDMV;
my ( $NCLRS1, $NCLRS2 ) = ( 14, 7 );
#
#
# Empirically determined vector thinning data
# Starting from the pole, each row of vectors is weeded, mod the
# value of this data.
#
my $NROWS = 11;
my @ITHIN = ( 90,15,5,5,4,4,3,3,2,2,2 );
#
# Indices used for vector coloring
#
my @ICLR1 = ( 10, 17, 24, 31, 38, 45, 52, 60, 67,  74, 81, 88, 95, 102 );

#
# Define a set of RGB color triples for vector colors
#
   my @RGB1 = (
   [    0.0,1.0,1.0,  ],
   [    0.0745098,0.92549,0.92549,  ],
   [    0.152941,0.847059,0.847059,  ],
   [    0.231373,0.768627,0.768627,  ],
   [    0.305882,0.694118,0.694118,  ],
   [    0.384314,0.615686,0.615686,  ],
   [    0.462745,0.537255,0.537255,  ],
   [    0.537255,0.462745,0.462745,  ],
   [    0.615686,0.384314,0.384314,  ],
   [    0.694118,0.305882,0.305882,  ],
   [    0.768627,0.231373,0.23137,  ],
   [    0.847059,0.152941,0.152941,  ],
   [    0.92549,0.0745098,0.074509,  ],
   [    1.0,0.0,0.0,   ],
   );
#
# Indices used for coloring other plot features; be careful not
# to duplicate any color indices in ICLR1
#
my @ICLR2 = ( 0, 1, 2, 149, 225, 175, 176 );
#
# RGB values for other plot features
#
   my @RGB2 = (
   [     1.0,1.0,1.0,  ],
   [     0.0,0.0,0.0,  ],
   [     0.9,0.9,0.9,  ],
   [     0.6,0.6,0.6,  ],
   [     0.3,0.3,0.3,  ],
   [     0.8,0.9,1.0,  ],
   [     0.25,0.0,0.5  ],
   );
#
# Set up auxiliary colors
#
for my $I ( 1 .. $NCLRS2 ) {
  &NCAR::gscr(1,$ICLR2[$I-1],@{ $RGB2[$I-1] });
}
#
# Read the input array data
#
&RDDATA($U,$V,$P,$MSIZE,$NSIZE);
#
# Message the data to eliminate surplus of vectors near the pole
#
for( my $J = $NSIZE; $J >= $NSIZE-$NROWS+1; $J-- ) {
  for my $I ( 1 .. $MSIZE ) {
    if( ( $I % $ITHIN[$NSIZE-$J] ) != 0 ) {
      set( $U, $I-1, $J-1, -9999.0 );
    }
  }
}


#       
# Set up the EZMAP projection
#         
&NCAR::mapset('CO',
              float( [   20.0, 0 ] ),
	      float( [ -180.0, 0 ] ),
	      float( [   20.0, 0 ] ),
	      float( [    0.0, 0 ] ),
	      );
&NCAR::maproj('ST',90.0,180.0,45.0);
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
&NCAR::vvsetr( 'XC1 -- Lower X Bound', -180.0 );
&NCAR::vvsetr( 'XCM -- Upper X Bound', 180.0 );
&NCAR::vvsetr( 'YC1 -- Lower X Bound', -90.0 );
&NCAR::vvsetr( 'YCN -- Upper Y Bound', 90.0 );
#
&NCAR::vvseti( 'SVF -- Special Values Flag', 3 );
&NCAR::vvsetr( 'USV -- U Special Value', -9999.0 );
&NCAR::vvsetr( 'VSV -- V Special Value', -9999.0 );
&NCAR::vvsetr( 'PSV - P Special Value', -9999.0 );
&NCAR::vvseti( 'SPC - P Special Color', 1 );
#
# Do the equivalent Conpack setup; note that the special value
# parameter works a bit differently, and also Conpack requires
# an Out of Range value to be set whenever the data grid extends
# outside the map boundaries. The standard value for the default
# version of CPMPXY is 1.0E12
#
&NCAR::cpseti( 'MAP -- Mapping Flag', 1 );
&NCAR::cpseti( 'SET -- Set Call Flag', 0 );
&NCAR::cpsetr( 'XC1 -- Lower X Bound', -180.0 );
&NCAR::cpsetr( 'XCM -- Upper X Bound', 180.0 );
&NCAR::cpsetr( 'YC1 -- Lower X Bound', -90.0 );
&NCAR::cpsetr( 'YCN -- Upper Y Bound', 90.0 );
&NCAR::cpsetr( 'SPV -- Special Value', -9999.0 );
&NCAR::cpsetr( 'ORV -- Out of Range Value', 1.0E12 );
#
# Set Conpack graphics text parameters
#
&SETCGT;
#
# Turn on statistics reporting
#
&NCAR::vvseti( 'VST -- Vector Statistics', 1 );
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
&SETCLA($NCLV, $ICLR2[5],$ICLR2[2]);
#
# Initialize the area map, and add the Conpack labels to the area map
#
&NCAR::arinam ($IAM,$IAREAL);
&NCAR::cplbam ($P,$RWRK,$IWRK,$IAM);
#
# Set up vector color processing
#
&NCAR::vvseti( 'MSK -- Vector Masking', 1 );
&NCAR::vvseti( 'CTV -- Color Thresholds Value', 2 );
&NCAR::vvseti( 'NLV -- Number Of Levels', $NCLRS1 );

for my $I ( 1 .. $NCLRS1 ) {
&NCAR::gscr(1,$ICLR1[$I-1],@{ $RGB1[$I-1] });
&NCAR::vvseti( 'PAI -- Parameter Array Index', $I );
&NCAR::vvseti( 'CLR -- GKS Color Index', $ICLR1[$I-1] );
}

for my $I ( 1 .. 6 ) {
#
# For the last frame modify the color table for a black background
# and modify the contour attributes
#
  if( $I == 6 ) {
  &NCAR::gscr(1,$ICLR2[0], @{ $RGB2[1] });
  &NCAR::gscr(1,$ICLR2[1], @{ $RGB2[0] });
  &SETCLA($NCLV, $ICLR2[6],$ICLR2[2]);
  }
#
# Draw the masked contour lines
#
  if( ( $I == 3  ) || ( $I >= 5 ) ) {
  &NCAR::cpcldm ($P,$RWRK,$IWRK,$IAM,\&DRAWCL);
  }
#
# Draw the continental outline with a wide line
#
  if( ( $I == 2 ) || ( $I >= 5 ) ) {
  my $ICOL=$ICLR2[2];
  if( $I > 5 ) { $ICOL=$ICLR2[4]; }
  &NCAR::mapsti('C5 - Continental Outline Color',$ICOL);
  &NCAR::gslwsc(8.0);
  &NCAR::maplot;
  }
  &NCAR::gslwsc(1.0);
#
# Draw the map grid
#
  if( ( $I == 1 ) || ( $I >= 5 ) ) {
  &NCAR::mapsti('C2 - Grid',$ICLR2[3]);
  &NCAR::gsplci($ICLR2[1]);
  &NCAR::mapgrm ($IAM,$XCRA,$YCRA,$MCRA,$IAAI,$IAGI,$NOGI,\&DRAWCL);
  &NCAR::gsplci(1);
  }
#
  if( ( $I == 4 ) || ( $I >= 5 ) ) {
#
# Initialize Vectors
#
  &NCAR::vvinit ($U,$MSIZE,$V,$MSIZE,$P,$MSIZE,$MSIZE,$NSIZE,float([ 0 ]),$IDM);
#
# Adjust vector rendering options
#
&NCAR::vvsetr( 'AMN -- Arrow Minimum Size', 0.007 );
&NCAR::vvsetr( 'LWD -- Vector Line Width', 1.75 );
&NCAR::vvgetr( 'VMN -- Minimum Vector', my $VMN );
&NCAR::vvgetr( 'VMX -- Maximum Vector', my $VMX );
&NCAR::vvsetr( 'VLC -- Vector Low Cutoff', $VMN+0.1*($VMX-$VMN) );
&NCAR::vvgetr( 'DMX -- Device Maximum Vector Length', my $DMX );
  &NCAR::getset( my ( $VL,$VR,$VB,$VT,$UL,$UR,$UB,$UT,$LL ) );
&NCAR::vvsetr( 'VRL - Vector Realized Length', 4.0*$DMX/($VR-$VL) );
&NCAR::vvsetr( 'VFR -- Vector Fractional Minimum', 0.4 );
#
# Draw the vector field plot
#
  &NCAR::vvectr ($U,$V,$P,$IAM,\&VVUDMV,float([]));
  }
#
# Draw continental outlines again with thin line and brighter
#
  if( ( $I == 2 ) || ( $I >= 5 ) ) {
  &NCAR::mapsti('C5 - Continental Outline Color',$ICLR2[1]);
  &NCAR::maplot;
  }
#
# Draw labels last
#
  if( ( $I == 3 ) || ( $I >= 5 ) ) {
  if( $I > 5 ) {
&NCAR::cpseti( 'HLB', 1 );
  &NCAR::gsfais(0);
  } else {
&NCAR::cpseti( 'HLB', 3 );
  &NCAR::gsfais(1);
  }
  &NCAR::cplbdr ($P,$RWRK,$IWRK);
  }
#
# Draw a perimeter boundary and eject the frame
#
  &NCAR::perim(1,0,1,0);
  &NCAR::frame;
#
}



sub RDDATA {
  my ( $U,$V,$P,$M,$N ) = @_;
#
# Read the data arrays from the standard input 
#
  my @D;
  open FILE, "<data/ffex05.dat";
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
}
#
#
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
#
# =====================================================================
#
sub SETCLA {
  my ( $NCLV, $ICLCLR, $IAXCLR ) = @_;
#
# Sets Contour Line Attributes
#
  for my $ICLV ( 1 .. $NCLV ) {
#
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', $ICLV );
&NCAR::cpgeti( 'CLU - CONTOUR LEVEL USE FLAG', my $ICLU );
&NCAR::cpseti( 'CLL - CONTOUR-LINE LINE WIDTH', 3 );
&NCAR::cpseti( 'CLC - CONTOUR-LINE COLOR', $ICLCLR );
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
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE FLAG', 0 );
&NCAR::cpsetr( 'CLL - CONTOUR LEVEL LINE WIDTH', 2. );
&NCAR::cpseti( 'CLC - CONTOUR LEVEL LINE COLOR', $IAXCLR );
#
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', -2 );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE FLAG', 1 );
&NCAR::cpsetr( 'CLL - CONTOUR LEVEL LINE WIDTH', 2. );
&NCAR::cpseti( 'CLC - CONTOUR LEVEL LINE COLOR', $IAXCLR );
#
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', -3 );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE FLAG', 1 );
&NCAR::cpsetr( 'CLL - CONTOUR LEVEL LINE WIDTH', 2. );
&NCAR::cpseti( 'CLC - CONTOUR LEVEL LINE COLOR', $IAXCLR );
#
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/ffex05.ncgm';

sub VVUDMV {
  my ( $XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
  my $IPMXCT=64;
  my $XC = zeroes float, $IPMXCT;
  my $YC = zeroes float, $IPMXCT;
  my $ICNT = 0;

  for my $I ( 1 .. $NAI ) {
     return if( at( $IAI, $I-1 ) < 0 );
  }
#
  &NCAR::vvgeti('AST',my $IAS);
#
# Depending on the arrow style, draw a polyline or a filled polygon
#
  if( $IAS == 0 ) {
    &NCAR::gpl($NCS,$XCS,$YCS);
    return;
  }
#
# If the 'filled' arrows are hollow, just draw the line as above
#
  &NCAR::vvgeti('ACM', my $ICM);
  if( $ICM == -1 ) {
    &NCAR::gpl($NCS,$XCS,$YCS);
    return;
  }
#
# This routine to draw filled arrows is rather cumbersome and
# completely eliminates arrows that partially intrude into
# a masked area
#
  if( $ICNT != 0 ) {
    if( ( at( $XCS, 0 ) != at( $XC, $ICNT-1 ) ) ||
        ( at( $YCS, 0 ) != at( $YC, $ICNT-1 ) ) ) {
      $ICNT = 0;
   } elsif( $ICNT + $NCS - 1 > $IPMXCT) {
#
# If the buffer size is exceeded throw away the points involved
# Uncomment the following to print out an error message in this case
#
#     WRITE(*,*) "ERROR IN VVUDMV: LOCAL BUFFER OVERFLOW"
#
     $ICNT = 0;
   } else {
     for my $I ( 2 .. $NCS ) {
        $ICNT = $ICNT+1;
        set( $XC, $ICNT-1, at( $XCS, $I-1 ) );
        set( $YC, $ICNT-1, at( $YCS, $I-1 ) );
     }
#
# If the points form a closed polygon draw them and empty the buffer
#
     if( ( at( $XC, 0 ) == at( $XC, $ICNT-1 ) ) &&
         ( at( $YC, 0 ) == at( $YC, $ICNT-1 ) ) ) {
#
       &NCAR::vvgeti('AFO',my $IFO);
       if( ( $IFO > 0 ) && ( $ICM > -2 ) ) {
          &NCAR::gpl($ICNT,$XC,$YC);
       }
       &NCAR::GFA($ICNT,$XC,$YC);
       if( ( $IFO <= 0 ) && ( $ICM > -2 ) ) {
         &NCAR::gpl($ICNT,$XC,$YC);
       }
#
       $ICNT = 0;
     }
     return;
    }
  }
#
# Draw the polygon if the points close; otherwise buffer the points.
#
  if( ( at( $XCS, 0 ) == at( $XCS, $NCS-1 ) ) &&
      ( at( $YCS, 0 ) == at( $YCS, $NCS-1 ) ) ) {
#
      &NCAR::vvgeti('ACM',my $ICM);
      &NCAR::vvgeti('AFO',my $IFO);
      if( ( $IFO > 0 ) && ( $ICM > -2 ) ) {
         &NCAR::gpl($NCS,$XCS,$YCS);
      }
      &NCAR::gfa($NCS,$XCS,$YCS);
      if( ( $IFO >= 0 ) && ( $ICM < -2 ) ) {
         &NCAR::gpl($NCS,$XCS,$YCS);
      }
#     
  } else {
      for my $I ( 1 .. $NCS ) {
         $ICNT = $ICNT+1;
         set( $XC, $ICNT-1, at( $XCS, $I-1 ) );
         set( $YC, $ICNT-1, at( $YCS, $I-1 ) );
      }
  }
#
# Done.
#
}
