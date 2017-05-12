# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print'

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
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
# This example overlays vectors on a polar contour plot using 
# data generated with a randomizing algorithm. The first frame colors
# the vectors according to the data used to generate the contour plot,
# with the result that the color of the vectors corresponds to the 
# contour level at each location. In the second frame the vectors 
# are colored by magnitude.
# 
# The contour, vector field component, and area map array declarations:
#
my ( $MSIZE, $NSIZE ) = ( 33, 33 );
my $LAMA=25000;
my $ZDAT = zeroes float, $NSIZE, $MSIZE;
my $U = zeroes float, 60, 60;
my $V = zeroes float, 60, 60;
my $IAMA = zeroes long, $LAMA;
#
# Workspace arrays for Conpack:
#
my $RWRK = zeroes float, 5000;
my $IWRK = zeroes long, 1000;
#
# ARSCAM arrays:
#
my $XCRA = zeroes float, 1000;
my $YCRA = zeroes float, 1000;
my $IARA = zeroes long, 10;
my $IGRA = zeroes long, 10;
#
# Declare the masked rendering routines for drawing and shading the
# contour plot, as well as for drawing the vectors
#
#     EXTERNAL DRAWCL
#     EXTERNAL SHADER
#     EXTERNAL VVUDMV
#
my @t;
open DAT, "<data/vvex01.ZDAT.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split m/\s+/o, $t;
}
close DAT;
for my $J ( 1 .. $NSIZE ) {
  for my $I ( 1 .. $MSIZE ) {
    set( $ZDAT, $J-1, $I-1, shift( @t ) );
  }
}
#
for my $I ( 1 .. $MSIZE ) {
  for my $J ( 1 .. $NSIZE ) {
    if( ( ($I-20)*($I-20) + ($J-10)*($J-10) ) < 25 ) { 
      set( $ZDAT, $J-1, $I-1, 1.E36 );
    }
  }
}
#
# Subroutine GENARA generates smoothly varying random data in its 
# second array argument based upon the contents of the first. Call it
# twice to randomize both the U and V vector component data arrays.
# Then set up the color table.
#
open DAT, "<data/vvex01.U.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split m/\s+/o, $t;
}
close DAT;
for my $J ( 1 .. 60 ) {
  for my $I ( 1 .. 60 ) {
    set( $U, $J-1, $I-1, shift( @t ) );
  }
}
open DAT, "<data/vvex01.V.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split m/\s+/o, $t;
}
close DAT;
for my $J ( 1 .. 60 ) {
  for my $I ( 1 .. 60 ) {
    set( $V, $J-1, $I-1, shift( @t ) );
  }
}

&DFCLRS() ;
#
# Conpack setup:
# ===============================================================
# Set up a polar coordinate system mapping for Conpack
#
&NCAR::set    (0.05,0.95,0.05,0.95,-1.0,1.0,-1.0,1.0,1);
&NCAR::cpseti ('MAP - Mapping Function',2);
&NCAR::cpseti ('SET - Do-Set-Call Flag',0);
&NCAR::cpsetr ('XC1 - Rho At I = 1',.1);
&NCAR::cpsetr ('XCM - Rho At I = M',1.);
&NCAR::cpsetr ('YC1 - Theta At J = 1',0.0);
&NCAR::cpsetr ('YCN - Theta At J = N',360.0);
#
# Enable special value processing and outline special value regions
#
&NCAR::cpsetr ('SPV - Special Value',1.E36);
&NCAR::cpseti ('PAI - Parameter Array Index',-2);
&NCAR::cpseti ('CLU - Contour Level Use Flag',1);
&NCAR::cpsetr ('CLL - Contour Level Line Width',2.);
#
# Adjust Conpack labelling and outline the data field.
#
&NCAR::cpseti ('LLP - Line Label Positioning',3);
&NCAR::cpseti ('RWC - Real Workspace For Contours',200);
&NCAR::cpseti ('HLB - High/Low Label Box Flag',1);
&NCAR::cpseti ('HLO - High/Low Label Overlap Flag',11);
&NCAR::cpsetr ('CWM - Character Width Multiplier',1.25);
&NCAR::cpseti ('PAI - Parameter Array Index',-1);
&NCAR::cpseti ('CLU - Contour Level Use Flag',1);
&NCAR::cpsetr ('CLL - Contour Level Line Width',2.);
#
# Initialize the drawing of the contour plot, and tell Conpack 
# to pick the contour levels.
#
&NCAR::cprect ($ZDAT,$MSIZE,$MSIZE,$NSIZE,$RWRK,5000,$IWRK,1000);
&NCAR::cppkcl ($ZDAT,$RWRK,$IWRK);
#
# Set the attributes of the contour lines
#
&NCAR::cpgeti ('NCL - Number Of Contour Levels',my $NCLV);
for my $ICLV ( 1 .. $NCLV ) {
  &NCAR::cpseti ('PAI - Parameter Array Index',$ICLV);
  &NCAR::cpgeti ('CLU - Contour Level Use Flag',my $ICLU);
  if( $ICLU == 3 ) {
    &NCAR::cpseti ('CLL - Contour-Line Line Width',2);
  }
  &NCAR::cpseti ('AIA - Area Identifier Above Level',0);
  &NCAR::cpseti ('AIB - Area Identifier Below Level',0);
}
#
# Add two new levels for which no contour lines are to be drawn, but
# between which shading is to be done.
#
$NCLV=$NCLV+2;
&NCAR::cpseti ('NCL - Number Of Contour Levels',$NCLV);
&NCAR::cpseti ('PAI - Parameter Array Index',$NCLV-1);
&NCAR::cpsetr ('CLV - Contour Level Value',-.15);
&NCAR::cpseti ('CLU - Contour Level Use Flag',0);
&NCAR::cpseti ('AIA - Area Identifier Above Level',1);
&NCAR::cpseti ('AIB - Area Identifier Below Level',2);
&NCAR::cpseti ('PAI - Parameter Array Index',$NCLV);
&NCAR::cpsetr ('CLV - Contour Level Value',+.15);
&NCAR::cpseti ('CLU - Contour Level Use Flag',0);
&NCAR::cpseti ('AIA - Area Identifier Above Level',3);
&NCAR::cpseti ('AIB - Area Identifier Below Level',1);
#
# Initialize the area map and draw the contour labels into it.
#
&NCAR::arinam ($IAMA,$LAMA);
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Vectors setup:
# ==================================================================
# Set the mapping flag for the polar transformation.
# Set the X,Y array index mapping parameters to the same values used
# bythe Conpack CPSET routines above. Turn on masking and turn the
# Set call flag off.
#
&NCAR::vvseti('MAP -- Mapping Flag', 2);
&NCAR::vvseti('SET -- Set Call Flag', 0);
&NCAR::vvsetr('XC1 -- Lower X Bound', 0.1);
&NCAR::vvsetr('XCM -- Upper X Bound', 1.0);
&NCAR::vvsetr('YC1 -- Lower X Bound', 0.0);
&NCAR::vvsetr('YCN -- Upper Y Bound', 360.0);
&NCAR::vvseti('MSK -- Area Mask Flag', 1);
#     
# Enable special value processing for the P array to eliminate
# vectors from the special value region. This is not really required
# in this case since the masking routine eliminates these vectors.
#     
&NCAR::vvseti('SPC -- P Special Value Color', 0);
&NCAR::vvsetr('PSV -- P Special Value', 1.E36);
#
# Enable vector coloring
#
&NCAR::vvseti('NLV - Number of Levels', 14);
for my $I ( 1 .. 14 ) {
  &NCAR::vvseti('PAI -- Parameter Array Index', $I);
  &NCAR::vvseti('CLR -- GKS Color Index', $I+1);
}
#
# Set up miscellaneous attribute parameters
#     
&NCAR::vvsetr('LWD -- Vector Linewidth', 2.0);
&NCAR::vvsetr('AMN -- Arrow Minimum Size', 0.01);
&NCAR::vvseti('VPO -- Vector Position Method', 0);
&NCAR::vvseti('XIN - X Grid Increment', 2);
#     
# Move the minimum and maximum vector text blocks out of the
# way of the text that Conpack puts out.
#
&NCAR::vvsetr('MNX - Minimum Vector X Pos', 0.0);
&NCAR::vvsetr('MXX - Maximum Vector X Pos', 0.33);
&NCAR::vvseti('MNP - Minimum Vector Justification', 2);
&NCAR::vvseti('MXP - Maximum Vector Justification', 4);
#
# Turn on statistics
#
&NCAR::vvseti('VST - Vector statistics', 1);
#
# Drawing loop
# ===================================================================
# Draw the contour plot with vectors overlaid twice. In the first
# plot Vectors uses the same data as Conpack for the independent
# scalar array. Therefore the colors of the vectors correspond to the
# contours. The second plot shows the vectors colored by magnitude.
#
for my $K ( 1 .. 2 ) {
#
# First draw masked contour lines, then labels, then put the
# contour lines in the area map for shading by ARSCAM
#
  &NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&DRAWCL);
  &NCAR::cplbdr ($ZDAT,$RWRK,$IWRK);
  &NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
  &NCAR::arscam ($IAMA,$XCRA,$YCRA,1000,$IARA,$IGRA,10,\&SHADER);
#
# Choose between vector magnitude and scalar array coloring
#
  if( $K == 1 ) {
    &NCAR::vvseti('CTV -- Color Threshold Value', 2);
  } else {
    &NCAR::vvseti('CTV -- Color Threshold Value', 1);
  }
#
# Initialize Vectors
#
  &NCAR::vvinit ($U,60,$V,60,$ZDAT,$MSIZE,$MSIZE,$NSIZE,float([]),0);
#
# Remove the bottom 05% of the vectors
#
  &NCAR::vvgetr('VMX -- Max Vector Magnitude',$VMX);
  &NCAR::vvgetr('VMN -- Min Vector Magnitude',$VMN);
  &NCAR::vvsetr('VLC -- Vector Low Cutoff',$VMN+0.05*($VMX-$VMN));
#
# Increase the size of the longest vector by 50% from its default
# value and make the shortest one fourth the length of the longest.
#
  &NCAR::vvgetr('DMX -- Max Vector Device Magnitude',my $DMX);
  &NCAR::getset( my ( $VL,$VR,$VB,$VT,$UL,$UR,$UB,$UT,$LL ) );
  my $VRL = 1.5 * $DMX / ($VR - $VL);
  &NCAR::vvsetr('VRL - Vector Realized Length', $VRL);
  &NCAR::vvsetr('VFR -- Vector Fractional Minimum', 0.25);
#
# Call VVECTR to draw the vectors, using the same area map that
# the Conpack routines used. The 'Draw Masked Vector' routine 
# used is the one supplied with the Velocity Vector Utility.
#
  &NCAR::vvectr ($U,$V,$ZDAT,$IAMA,\&VVUDMV,float([]));
#
# Put a boundary line at the edge of the plotter frame.
#
  &NCAR::Test::bndary();
#
# Advance the frame.
#     
  &NCAR::frame();
#
}
#
sub DRAWCL {
  my ($XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
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
  if( $IDR != 0 ) { &NCAR::curved( $XCS, $YCS, $NCS ); }
#
# Done.
#
}
#

sub SHADER {
  my ($XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
#
# This version of SHADER shades the polygon whose edge is defined by
# the points ((XCS(I),YCS(I)),I=1,NCS) if and only, relative to edge
# group 3, its area identifier is a 1.  The package SOFTFILL is used
# to do the shading.
#
#
# Define workspaces for the shading routine.
#
  my $DST = zeroes float, 1100;
  my $IND = zeroes long, 1200;
#
# Turn off shading.
#
  my $ISH=0;
#
# If the area identifier for group 3 is a 1, turn on shading.
#
  for my $I ( 1 .. $NAI ) {
    if( ( at( $IAI, $I-1 ) == 3 ) && ( at( $IAI, $I-1 ) == 1 ) ) { $ISH = 1; }
  }
#
# If shading is turned on, shade the area.  The last point of the
# edge is redundant and may be omitted.
#
  if( $ISH != 0 ) {
    &NCAR::sfseti ('ANGLE',45);
    &NCAR::sfsetr ('SPACING',.006);
    &NCAR::sfwrld ($XCS,$YCS,$NCS-1,$DST,1100,$IND,1200);
    &NCAR::sfseti ('ANGLE',135);
    &NCAR::sfnorm ($XCS,$YCS,$NCS-1,$DST,1100,$IND,1200);
  }
#
# Done.
#
}
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

sub DFCLRS {
  my $NCLRS=16;
  my @RGBV = (
     [ 0.00 , 0.00 , 0.00 ],
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
  for my $I ( 1 .. $NCLRS ) {
    &NCAR::gscr( 1,$I-1,@{ $RGBV[$I-1] });
  }
}

&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();


rename 'gmeta', 'ncgm/vvex01.ncgm';
