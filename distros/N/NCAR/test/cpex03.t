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
use NCAR::Test qw( bndary min max gendat labtop capsap shader drawcl );
use strict;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

print STDERR "\n";

#
# Declare an array to hold the data to be contoured.
#
my $ZDAT = zeroes float, 33, 33;
#
# Declare the required real and integer workspaces.
#
my $RWRK = zeroes float, 5000;
my $IWRK = zeroes long, 1000;
#
# Declare an array to hold an area map.
#
my $IAMA = zeroes long, 20000;
#
# Declare the arrays needed by ARSCAM for x/y coordinates.
#
my $XCRA = zeroes float, 1000;
my $YCRA = zeroes float, 1000;
#
# Declare the arrays needed by ARSCAM for area and group identifiers.
#
my $IARA = zeroes long, 10;
my $IGRA = zeroes long, 10;
#
# Declare an array to hold the GKS "aspect source flags".
#
my $IASF = long [ ( 1 ) x 13 ];
#
# Declare the routine which will draw contour lines, avoiding labels.
#
#       EXTERNAL DRAWCL
#
# Declare the routine which does the shading.
#
#       EXTERNAL SHADER
#
# Dimension a character variable to hold plot labels.
#
my $LABL;
#
# Declare common blocks required for communication with CPMPXY.
#
my $XFOI = zeroes float, 33;
my $YFOJ = zeroes float, 33;
my $XFIJ = zeroes float, 33, 33;
my $YFIJ = zeroes float, 33, 33;
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Set all the GKS aspect source flags to "individual".
#
&NCAR::gsasf ($IASF);
#
# Turn on the positioning of labels by the penalty scheme and provide a
# little more room for X and Y coordinates defining contour lines, so
# as not to have labels right next to each other on a contour line.
#
&NCAR::cpseti ('LLP - LINE LABEL POSITIONING',3);
&NCAR::cpseti ('RWC - REAL WORKSPACE FOR CONTOURS',200);
#
# Turn on the drawing of the high and low label boxes.
#
&NCAR::cpseti ('HLB - HIGH/LOW LABEL BOX FLAG',1);
#
# Tell CONPACK to delete high/low labels which overlap the informational
# label or another high/low label, but to move those which overlap the
# edge inward a little.
#
&NCAR::cpseti ('HLO - HIGH/LOW LABEL OVERLAP FLAG',11);
#
# Make all CONPACK-written characters a little bigger.
#
&NCAR::cpsetr ('CWM - CHARACTER WIDTH MULTIPLIER',1.25);
#
# Turn on the drawing of the grid edge ("contour line number -1") and
# thicken it somewhat.
#
&NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',-1);
&NCAR::cpseti ('CLU - CONTOUR LEVEL USE FLAG',1);
&NCAR::cpsetr ('CLL - CONTOUR LEVEL LINE WIDTH',2.);
#
# Tell CONPACK to do no SET call.
#
&NCAR::cpseti ('SET - DO-SET-CALL FLAG',0);
#
# Turn on the special-value feature and the outlining of special-value
# areas ("contour line number -2"), using a double-width line.
#
&NCAR::cpsetr ('SPV - SPECIAL VALUE',1.E36);
&NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',-2);
&NCAR::cpseti ('CLU - CONTOUR LEVEL USE FLAG',1);
&NCAR::cpsetr ('CLL - CONTOUR LEVEL LINE WIDTH',2.);
#
# Generate an array of test data.
#
my @t;
open DAT, "<data/cpex03.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split m/\s+/o, $t;
}
close DAT;
for my $I ( 1 .. 33 ) {
  for my $J ( 1 .. 33 ) {
    set( $ZDAT, $J-1, $I-1, shift( @t ) );
  }
}
#
# Put special values in a roughly circular area.
#
for my $I ( 1 .. 33 ) {
  for my $J ( 1 .. 33 ) {
    if( ( ($I-20)*($I-20)+($J-10)*($J-10) ) < 25 ) {
      set( $ZDAT, $J-1, $I-1, 1.E36 );
    }
  }
}

sub Log10 {
  my $x = shift;
  return log( $x ) / log( 10 );
}
#
# Do four different plots, one in each quadrant.
#
for my $IPLT ( 1 .. 4 ) {
#
# Compute viewport parameters.
#
  my $XVPL=.0250+.5000*(($IPLT-1)%2);
  my $XVPR=.4750+.5000*(($IPLT-1)%2);
  my $YVPB=.0250+.5000*int((4-$IPLT)/2);
  my $YVPT=.4750+.5000*int((4-$IPLT)/2);
#
# For each of the four plots, use a different mapping function and
# create a different background.
#
  &NCAR::cpseti ('MAP - MAPPING FUNCTION',$IPLT);
#
# EZMAP.
#
  if( $IPLT == 1 ) {
    &NCAR::mapsti ('GR - GRID INTERVAL',30);
    &NCAR::mapstc ('OU - OUTLINE DATASET','CO');
    &NCAR::mapsti ('DO - DOTTING OF OUTLINES',1);
    &NCAR::mappos ($XVPL,$XVPR,$YVPB,$YVPT);
    &NCAR::maproj ('OR - ORTHOGRAPHIC',40.,-95.,0.);
    &NCAR::mapset ('MA - MAXIMAL AREA',
                   float( [ 0., 0. ] ),
                   float( [ 0., 0. ] ),
                   float( [ 0., 0. ] ),
                   float( [ 0., 0. ] )
                  );
    &NCAR::mapdrw();
    &NCAR::cpsetr ('XC1 - LONGITUDE AT I = 1',-160.);
    &NCAR::cpsetr ('XCM - LONGITUDE AT I = M',-30.);
    &NCAR::cpsetr ('YC1 - LATITUDE AT J = 1',-10.);
    &NCAR::cpsetr ('YCN - LATITUDE AT J = N',70.);
#
# Polar coordinates.
#
  } elsif( $IPLT == 2 ) {
    &NCAR::cpsetr ('XC1 - RHO AT I = 1',.1);
    &NCAR::cpsetr ('XCM - RHO AT I = M',1.);
    &NCAR::cpsetr ('YC1 - THETA AT J = 1',0.);
    &NCAR::cpsetr ('YCN - THETA AT J = N',90.);
    &NCAR::set    ($XVPL,$XVPR,$YVPB,$YVPT,0.,1.,0.,1.,1);
#
# Rectangular, irregularly-spaced.
#
  } elsif( $IPLT == 3 ) {
    &NCAR::cpsetr ('XC1 - X COORDINATE AT I = 1',1.);
    &NCAR::cpsetr ('XCM - X COORDINATE AT I = M',33.);
    &NCAR::cpsetr ('YC1 - Y COORDINATE AT J = 1',1.);
    &NCAR::cpsetr ('YCN - Y COORDINATE AT J = N',33.);
    &NCAR::set    ($XVPL,$XVPR,$YVPB,$YVPT,0.,1.,0.,1.,1);
    for my $I ( 1 .. 33 ) {
      set( $XFOI, $I-1, &Log10( 1.+9.*($I-1)/32. ) );
    }
    for my $J ( 1 .. 33 ) {
      set( $YFOJ, $J-1, &Log10( 1.+9.*($J-1)/32. ) );
    }
#
# Parameterized distortion.
#
  } elsif( $IPLT == 4 ) {
    &NCAR::cpsetr ('XC1 - X COORDINATE AT I = 1',1.);
    &NCAR::cpsetr ('XCM - X COORDINATE AT I = M',33.);
    &NCAR::cpsetr ('YC1 - Y COORDINATE AT J = 1',1.);
    &NCAR::cpsetr ('YCN - Y COORDINATE AT J = N',33.);
    &NCAR::set    ($XVPL,$XVPR,$YVPB,$YVPT,0.,1.,0.,1.,1);
    for my $I ( 1 .. 33 ) {
      for my $J ( 1 .. 33 ) {
        set( $XFIJ, $J-1, $I-1, ($I-1)/32.+((17-$I)/64.)*((16-abs($J-17))/16.) );
        set( $YFIJ, $J-1, $I-1, ($J-1)/32.+((17-$J)/64.)*((16-abs($I-17))/16.) );
      }
    }
#
  }
#
# Initialize the drawing of the contour plot.
#
  &NCAR::cprect ($ZDAT,33,33,33,$RWRK,5000,$IWRK,1000);
#
# Force the selection of contour levels, so that associated quantities
# may be tweaked.
#
  &NCAR::cppkcl ($ZDAT,$RWRK,$IWRK);
#
# Increase the line width for labelled levels and turn off the area
# identifiers for all levels.
#
  &NCAR::cpgeti ('NCL - NUMBER OF CONTOUR LEVELS',my $NCLV);
#
  for my $ICLV ( 1 .. $NCLV ) {
    &NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',$ICLV);
    &NCAR::cpgeti ('CLU - CONTOUR LEVEL USE FLAG',my $ICLU);
    if( $ICLU == 3 ) {
      &NCAR::cpseti ('CLL - CONTOUR-LINE LINE WIDTH',2);
    }
    &NCAR::cpseti ('AIA - AREA IDENTIFIER ABOVE LEVEL',0);
    &NCAR::cpseti ('AIB - AREA IDENTIFIER BELOW LEVEL',0);
  }
#
# Add two new levels for which no contour lines are to be drawn, but
# between which shading is to be done.
#
  $NCLV=$NCLV+2;
  &NCAR::cpseti ('NCL - NUMBER OF CONTOUR LEVELS',$NCLV);
#
  &NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',$NCLV-1);
  &NCAR::cpsetr ('CLV - CONTOUR LEVEL VALUE',-.15);
  &NCAR::cpseti ('CLU - CONTOUR LEVEL USE FLAG',0);
  &NCAR::cpseti ('AIA - AREA IDENTIFIER ABOVE LEVEL',1);
  &NCAR::cpseti ('AIB - AREA IDENTIFIER BELOW LEVEL',2);
  &NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',$NCLV);
  &NCAR::cpsetr ('CLV - CONTOUR LEVEL VALUE',+.15);
  &NCAR::cpseti ('CLU - CONTOUR LEVEL USE FLAG',0);
  &NCAR::cpseti ('AIA - AREA IDENTIFIER ABOVE LEVEL',3);
  &NCAR::cpseti ('AIB - AREA IDENTIFIER BELOW LEVEL',1);
#
# Draw the contour plot.
#
  &NCAR::arinam ($IAMA,20000);
  &NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
  &NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&DRAWCL);
  &NCAR::cplbdr ($ZDAT,$RWRK,$IWRK);
  &NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
  &NCAR::arscam ($IAMA,$XCRA,$YCRA,1000,$IARA,$IGRA,10,\&SHADER);
#
# Compute and print statistics for the plot and label it.
#
  $LABL= 'EXAMPLE 3-' . chr(ord('0')+$IPLT);
  &NCAR::Test::capsap ($LABL,$IAMA,20000);
  &NCAR::Test::labtop ($LABL,.017);
#
}
#
# Put a boundary line at the edge of the plotter frame.
#
&NCAR::Test::bndary();

sub NCAR::cpmpxy {
  my ($IMAP,$XINP,$YINP,$XOTP,$YOTP) = @_;
#
# This version of CPMPXY implements four different mappings:
#
#   IMAP = 1 implies an EZMAP mapping.  XINP and YINP are assumed to be
#   the longitude and latitude, in degrees, of a point on the globe.
#
#   IMAP = 2 implies a polar coordinate mapping.  XINP and YINP are
#   assumed to be values of rho and theta (in degrees).
#
#   IMAP = 3 implies an orthogonal, but unequally-spaced mapping.  XINP
#   is assumed to lie in the range from 1 to M, YINP in the range from
#   1 to N, where M and N are the dimensions of the grid.  The common
#   block CPMPC1 contains arrays XFOI and YFOJ giving the X coordinates
#   associated with I = 1 to M and the Y coordinates associated with
#   J = 1 to N.
#
#   IMAP = 4 implies a generalized distortion.  XINP is assumed to lie
#   in the range from 1 to M, YINP in the range from 1 to N, where M
#   and N are the dimensions of the grid.  The common block CPMPC2
#   contains arrays XFIJ and YFIJ, giving the X and Y coordinates
#   associated with index pairs (I,J).
#
# Do the mapping.
#
  if( $IMAP == 1 ) {
    &NCAR::maptrn ($YINP,$XINP,$XOTP,$YOTP);
  } elsif( $IMAP == 2 ) {
    $XOTP=$XINP*cos(.017453292519943*$YINP);
    $YOTP=$XINP*sin(.017453292519943*$YINP);
  } elsif( $IMAP == 3 ) {
    my $I=&NCAR::Test::max(1,&NCAR::Test::min(32,int($XINP)));
    my $J=&NCAR::Test::max(1,&NCAR::Test::min(32,int($YINP)));
    $XOTP=($I+1-$XINP)*at( $XFOI, $I-1 )+($XINP-$I)*at( $XFOI, $I );
    $YOTP=($J+1-$YINP)*at( $YFOJ, $J-1 )+($YINP-$J)*at( $YFOJ, $J );
  } elsif( $IMAP == 4 ) {
    my $I=&NCAR::Test::max(1,&NCAR::Test::min(32,int($XINP)));
    my $J=&NCAR::Test::max(1,&NCAR::Test::min(32,int($YINP)));
    $XOTP=(($J+1)-$YINP)*
       (($I+1-$XINP)*at( $XFIJ, $J-1, $I-1 )+($XINP-$I)*at( $XFIJ, $J-1, $I ))
       +($YINP-$J)*
       (($I+1-$XINP)*at( $XFIJ, $J, $I-1)+($XINP-$I)*at( $XFIJ, $J, $I ));
    $YOTP=($J+1-$YINP)*
       (($I+1-$XINP)*at( $YFIJ, $J-1, $I-1 )+($XINP-$I)*at( $YFIJ, $J-1, $I ))
       +($YINP-$J)*
       (($I+1-$XINP)*at( $YFIJ, $J, $I-1 )+($XINP-$I)*at( $YFIJ, $J, $I ));
  } else {
    $XOTP=$XINP;
    $YOTP=$YINP;
  }
  RETURN:
  ( $_[1], $_[2], $_[3], $_[4] ) = 
  ( $XINP, $YINP, $XOTP, $YOTP );  
  return;
}

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
  if( $IDR != 0 ) { &NCAR::curved($XCS,$YCS,$NCS); } 
#
# Done.
#
}

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
    if( ( at( $IAG, $I-1 ) == 3 ) && ( at( $IAI, $I-1 ) == 1 ) ) { $ISH=1; }
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

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/cpex03.ncgm';
