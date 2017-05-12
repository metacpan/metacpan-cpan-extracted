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
my ( $ISLIM, $NUMXOUT, $NUMYOUT ) = ( 171, 21, 21 );
my $IDIM = 2*$NUMXOUT*$NUMYOUT;
my $RAD2DEG = 57.29578;
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
my $Z = zeroes float, $ISLIM;
my $XI = zeroes float, $NUMXOUT;
my $YI = zeroes float, $NUMYOUT;
my $ZI = zeroes float, $NUMXOUT, $NUMYOUT;
my $RTMP = zeroes float, $NUMXOUT, $NUMYOUT;
my $U = zeroes float, $NUMXOUT, $NUMYOUT;
my $V = zeroes float, $NUMXOUT, $NUMYOUT;
#
my $IWORK = zeroes long, $IDIM;
my $X = float [
    1.16,  0.47,  0.29,  0.72,  0.52,  1.12,  0.33,  0.20,  0.30,
    0.78,  0.92,  0.52,  0.44,  0.22, -0.10,  0.11,  0.59,  1.13,
    0.68,  1.11,  0.93,  0.29,  0.74,  0.43,  0.87,  0.87, -0.10,
    0.26,  0.85,  0.00, -0.02,  1.01, -0.12,  0.65,  0.39,  0.96,
    0.39,  0.38,  0.94, -0.03, -0.17,  0.00,  0.03,  0.67, -0.06,
    0.82, -0.03,  1.08,  0.37,  1.02, -0.11, -0.13,  1.03,  0.61,
    0.26,  0.18,  0.62,  0.42,  1.03,  0.72,  0.97,  0.08,  1.18,
    0.00,  0.69,  0.10,  0.80,  0.06,  0.82,  0.20,  0.46,  0.37,
    1.16,  0.93,  1.09,  0.96,  1.00,  0.80,  0.01,  0.12,  1.01,
    0.48,  0.79,  0.04,  0.42,  0.48, -0.18,  1.16,  0.85,  0.97,
    0.14,  0.40,  0.78,  1.12,  1.19,  0.68,  0.65,  0.41,  0.90,
    0.84, -0.11, -0.01, -0.02, -0.10,  1.04,  0.58,  0.61,  0.12,
   -0.02, -0.03,  0.27,  1.17,  1.02,  0.16, -0.17,  1.03,  0.13,
    0.04, -0.03,  0.15,  0.00, -0.01,  0.91,  1.20,  0.54, -0.14,
    1.03,  0.93,  0.42,  0.36, -0.10,  0.57,  0.22,  0.74,  1.15,
    0.40,  0.82,  0.96,  1.09,  0.42,  1.13,  0.24,  0.51,  0.60,
    0.06,  0.38,  0.15,  0.59,  0.76,  1.16,  0.02,  0.86,  1.14,
    0.37,  0.38,  0.26,  0.26,  0.07,  0.87,  0.90,  0.83,  0.09,
    0.03,  0.56, -0.19,  0.51,  1.07, -0.13,  0.99,  0.84,  0.22 ];
my $Y = float [
   -0.11,  1.07,  1.11, -0.17,  0.08,  0.09,  0.91,  0.17, -0.02,
    0.83,  1.08,  0.87,  0.46,  0.66,  0.50, -0.14,  0.78,  1.08,
    0.65,  0.00,  1.03,  0.06,  0.69, -0.16,  0.02,  0.59,  0.19,
    0.54,  0.68,  0.95,  0.30,  0.77,  0.94,  0.76,  0.56,  0.12,
    0.05, -0.07,  1.01,  0.61,  1.04, -0.07,  0.46,  1.07,  0.87,
    0.11,  0.63,  0.06,  0.53,  0.95,  0.78,  0.48,  0.45,  0.77,
    0.78,  0.29,  0.38,  0.85, -0.10,  1.17,  0.35,  1.14, -0.04,
    0.34, -0.18,  0.78,  0.17,  0.63,  0.88, -0.12,  0.58, -0.12,
    1.00,  0.99,  0.45,  0.86, -0.15,  0.97,  0.99,  0.90,  0.42,
    0.61,  0.74,  0.41,  0.44,  1.08,  1.06,  1.18,  0.89,  0.74,
    0.74, -0.06,  0.00,  0.99,  0.03,  1.00, -0.04,  0.24,  0.65,
    0.12,  0.13, -0.09, -0.05,  1.03,  1.07, -0.02,  1.18,  0.19,
    0.03, -0.03,  0.86,  1.12,  0.38,  0.72, -0.20, -0.08, -0.18,
    0.32,  0.13, -0.19,  0.93,  0.81,  0.31,  1.09, -0.03,  1.01,
   -0.17,  0.84, -0.11,  0.45,  0.18,  0.23,  0.81,  0.39,  1.09,
   -0.05,  0.58,  0.53,  0.96,  0.43,  0.48,  0.96, -0.03,  1.13,
    1.16,  0.16,  1.15,  0.57,  0.13,  0.71,  0.35,  1.04,  0.62,
    1.03,  0.98,  0.31,  0.70,  0.97,  0.87,  1.14,  0.08,  1.19,
    0.88,  1.00,  0.51,  0.03,  0.17,  1.01,  0.44,  0.17, -0.11 ];
#
#  The data values for X and Y (defined in BLOCKDATA) are random numbers 
#  in the range  -0.2 to 1.2.  They are explicitly set so that they 
#  will be uniform across all compilers.
#
#
#  Define the function values.
#
for my $I ( 1 .. $ISLIM ) {
  set( $Z, $I-1, ( at( $X, $I-1 )-0.25 ) ** 2 + ( at( $Y, $I-1 )-0.50 ) ** 2 );
}
#
#  Define the output grid.
#
my $XMIN = 0.0;
my $XMAX = 1.0;
my $XINC = ($XMAX-$XMIN)/($NUMXOUT-1.) ;
for my $I ( 1 .. $NUMXOUT ) {
  set( $XI, $I-1, $XMIN+($I-1) * $XINC );
}
#
my $YMIN =  0.0;
my $YMAX =  1.0;
my $YINC = ($YMAX-$YMIN)/($NUMYOUT-1.);
for my $J ( 1 .. $NUMYOUT ) {
  set( $YI, $J-1, $YMIN+($J-1) * $YINC );
}
#
&NCAR::nnseti('SDI - compute slopes and aspects',1);
&NCAR::nnseti('IGR - use gradient estimates',1);
&NCAR::nnseti('RAD - return results in radians',1);
&NCAR::natgrids($ISLIM,$X,$Y,$Z,$NUMXOUT,$NUMYOUT,$XI,$YI,$ZI,my $IER);
#
#  Plot the interpolated surface.
#
#
# Open GKS and define the foreground and background color.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
&NCAR::gscr($IWKID, 0, 1.00, 1.00, 1.00);
&NCAR::gscr($IWKID, 1, 0.00, 0.00, 0.00);
&NCAR::gscr($IWKID, 2, 0.00, 1.00, 1.00);
&NCAR::gscr($IWKID, 3, 0.00, 1.00, 0.00);
&NCAR::gscr($IWKID, 4, 0.70, 1.00, 0.00);
&NCAR::gscr($IWKID, 5, 1.00, 1.00, 0.00);
&NCAR::gscr($IWKID, 6, 1.00, 0.75, 0.00);
&NCAR::gscr($IWKID, 7, 1.00, 0.50, 0.50);
&NCAR::gscr($IWKID, 8, 1.00, 0.00, 0.00);
#
&DRWSRF($NUMXOUT,$NUMYOUT,$XI,$YI,$ZI,10.,-25.,50.,$IWORK);
#
#  Get the aspects.
#
for my $J ( 1 .. $NUMYOUT ) {
  for my $I ( 1 .. $NUMXOUT ) {
    &NCAR::nngetaspects($I,$J,my $a,my $IER);
    set( $RTMP, $I-1, $J-1, $a );
  }
}
#
for my $I ( 1 .. $NUMXOUT ) {
  for my $J ( 1 .. $NUMYOUT ) {
    set( $U, $I-1, $J-1, sin( at( $RTMP, $I-1, $J-1 ) ) );
    set( $V, $I-1, $J-1, cos( at( $RTMP, $I-1, $J-1 ) ) );
  }
}
#
#  Plot the aspects as a vector plot.
#
&DRWVCT($NUMXOUT,$NUMYOUT,$U,$V);
#
#  Get the slopes; convert to degrees.
#
for my $I ( 1 .. $NUMXOUT ) {
  for my $J ( 1 .. $NUMYOUT ) {
    &NCAR::nngetslopes($I,$J,my $a,my $IER);
    set( $RTMP, $I-1, $J-1, $RAD2DEG * $a );
  }
}
#
#  Plot the slopes as a contour plot.
#
&DRWCON($NUMXOUT,$NUMYOUT,$XI,$YI,$RTMP);
#
# Close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();

# 
#
#
sub DRWSRF {
  my ($NX,$NY,$X,$Y,$Z,$S1,$S2,$S3,$IWK) = @_;
#
#  Procedure DRWSRF uses the NCAR Graphics function SRFACE to
#  draw a surface plot of the data values in Z.
# 
#  The point of observation is calculated from the 3D coordinate
#  (S1, S2, S3); the point looked at is the center of the surface.
# 
#   NX     -  Dimension of the X-axis variable X.
#   NY     -  Dimension of the Y-axis variable Y.
#   X      -  An array of X-axis values.
#   Y      -  An array of Y-axis values.
#   Z      -  An array dimensioned for NX x NY containing data
#             values for each (X,Y) coordinate.
#   S1     -  X value for the eye position.
#   S2     -  Y value for the eye position.
#   S3     -  Z value for the eye position.
#   IWK    -  Work space dimensioned for at least 2*NX*NY.
# 
#  
#
  my ( $IERRF, $LUNIT, $IWKID, $IWTYPE ) = ( 6, 2, 1, 8 );
#
#  Open GKS, open and activate a workstation.
#
  my $JTYPE = $IWTYPE;
  &NCAR::gqops(my $ISTATE);
  if( $ISTATE ==  0 ) {
    &NCAR::gopks ($IERRF, my $ISZDM);
    if( $JTYPE == 1 ) {
      &NCAR::ngsetc('ME','srf.ncgm');
    } elsif( ( $JTYPE >= 20 ) && ( $JTYPE <= 31 ) ) {
      &NCAR::ngsetc('ME','srf.ps');
    }
    &NCAR::gopwk ($IWKID, $LUNIT, $JTYPE);
    &NCAR::gscr($IWKID,0,1.,1.,1.);
    &NCAR::gscr($IWKID,1,0.,0.,0.);
    &NCAR::gacwk ($IWKID);
  }
#
#  Find the extreme values.
#
  my $XMN = at( $X, 0 );
  my $XMX = at( $X, 0 );
  my $YMN = at( $Y, 0 );
  my $YMX = at( $Y, 0 );
  my $ZMN = at( $Z, 0, 0 );
  my $ZMX = at( $Z, 0, 0 );
#
  for my $I ( 2 .. $NX ) {
    $XMN = &NCAR::Test::min($XMN,at( $X, $I-1 ));
    $XMX = &NCAR::Test::max($XMX,at( $X, $I-1 ));
  }
#
  for my $I ( 1 .. $NY ) {
    $YMN = &NCAR::Test::min($YMN,at( $Y, $I-1 ));
    $YMX = &NCAR::Test::max($YMX,at( $Y, $I-1 ));
  }
#
  for my $I ( 1 .. $NX ) {
    for my $J ( 1 .. $NY ) {
      $ZMN = &NCAR::Test::min($ZMN, at( $Z, $I-1, $J-1));
      $ZMX = &NCAR::Test::max($ZMX, at( $Z, $I-1, $J-1));
    }
  }
#
  my ( $ST1, $ST2, $ST3 );
  if( ( $S1 == 0 ) && ( $S2 == 0 ) && ( $S3 == 0 ) ) {
    $ST1 = -3.;
    $ST2 = -1.5;
    $ST3 = 0.75;
  } else {
    $ST1 = $S1;
    $ST2 = $S2;
    $ST3 = $S3;
  }
  my $S = float [
            5.*$ST1*($XMX-$XMN), 5.*$ST2*($YMX-$YMN), 5.*$ST3*($ZMX-$ZMN), 
            0.5*($XMX-$XMN),     0.5*($YMX-$YMN),     0.5*($ZMX-$ZMN)
  ];
#
  &NCAR::srface ($X,$Y,$Z,$IWK,$NX,$NX,$NY,$S,0.);
#
#  Close down GKS.
#
  if( $ISTATE == 0 ) {
    &NCAR::gdawk ($IWKID);
    &NCAR::gclwk ($IWKID);
    &NCAR::gclks();
  }
#
}
sub DRWVCT {
  my ($LX,$LY,$U,$V) = @_;
#
#  Where U and V are 2D arrays, this subroutine uses NCAR Graphics to
#  draw a vector plot of the vectors (U(I,J),V(I,J)) 
#  for I=1,LX and J=1,LY.
#
  my ( $IERRF, $LUNIT, $IWKID, $IWTYPE ) = ( 6, 2, 1, 8 );
#
  my $JTYPE = $IWTYPE;
  &NCAR::gqops( my $ISTATE );
  if( $ISTATE == 0 ) {
    &NCAR::gopks ($IERRF, my $ISZDM);
    if( $JTYPE == 1 ) {
      &NCAR::ngsetc('ME','vec.ncgm');
    } elsif( ($JTYPE >= 20) && ($JTYPE <= 31) ) {
      &NCAR::ngsetc('ME','vec.ps');
    }
    &NCAR::gopwk ($IWKID, $LUNIT, $JTYPE);
    &NCAR::gacwk ($IWKID);
    &NCAR::gscr($IWKID, 0, 1.00, 1.00, 1.00);
    &NCAR::gscr($IWKID, 1, 0.00, 0.00, 0.00);
  }
#
  &NCAR::vvinit($U,$LX,$V,$LY,float([0]),0,$LX,$LY,float([0]),1);
  &NCAR::vvsetc('MNT',' ');
  &NCAR::vvsetc('MXT',' ');
  &NCAR::vvectr($U,$V,float([0]),long([]),undef,float([0]));
  &NCAR::frame();
#
  if( $ISTATE == 0 ) {
    &NCAR::gdawk ($IWKID);
    &NCAR::gclwk ($IWKID);
    &NCAR::gclks();
  }
#
}
sub DRWCON {
  my ($NX,$NY,$XI,$YI,$ZDAT) = @_;
#
#  Use the NCAR Graphics CONPACK package to draw a color contour 
#  plot of the data in ZDAT.
#
  my ( $IERRF, $LUNIT, $IWKID, $IWTYPE ) = ( 6, 2, 1, 1 );
#
  my $RWRK = zeroes float, 2000;
  my $IWRK = zeroes long, 1000;
  my $IAMA = zeroes long, 20000;
  my $XCRA = zeroes float, 1000;
  my $YCRA = zeroes float, 1000;
  my $IAIA = zeroes long, 10;
  my $IGIA = zeroes long, 10;
#
#     EXTERNAL CPCOLR,CPDRPL
#
#  Open GKS if not open; open and activate a workstation; define
#  some colors.
#
  my $JTYPE = $IWTYPE;
  &NCAR::gqops(my $ISTATE);
  if( $ISTATE == 0 ) {
    &NCAR::gopks ($IERRF, my $ISZDM);
    if( $JTYPE == 1 ) {
      &NCAR::ngsetc('ME','con.ncgm');
    } elsif( ($JTYPE >= 20) && ($JTYPE <= 31) ) {
      &NCAR::ngsetc('ME','con.ps');
    }
    &NCAR::gopwk ($IWKID, $LUNIT, $JTYPE);
    &NCAR::gacwk ($IWKID);
    &NCAR::gscr($IWKID, 0, 1.00, 1.00, 1.00);
    &NCAR::gscr($IWKID, 1, 0.00, 0.00, 0.00);
    &NCAR::gscr($IWKID, 2, 0.00, 1.00, 1.00);
    &NCAR::gscr($IWKID, 3, 0.00, 1.00, 0.00);
    &NCAR::gscr($IWKID, 4, 0.70, 1.00, 0.00);
    &NCAR::gscr($IWKID, 5, 1.00, 1.00, 0.00);
    &NCAR::gscr($IWKID, 6, 1.00, 0.75, 0.00);
    &NCAR::gscr($IWKID, 7, 1.00, 0.50, 0.50);
    &NCAR::gscr($IWKID, 8, 1.00, 0.00, 0.00);
  }
#
  my $IERR = 0;
#
  &NCAR::cpseti('CLS - CONTOUR LEVEL SELECTOR',0);
  &NCAR::cpseti('NCL - NUMBER OF CONTOUR LEVELS',7);
#
  for my $I ( 1 .. 7 ) {
    &NCAR::cpseti('PAI - parameter array index',$I);
    &NCAR::cpsetr('CLV - contour level',10.*$I);
    &NCAR::cpseti('CLU - contour level use',3);
    &NCAR::cpseti('LLC - contour label color',1);
  }
#
# Initialize the drawing of the contour plot.
#
  &NCAR::cpsetr('VPL - viewport left',0.05);
  &NCAR::cpsetr('VPR - viewport right',0.95);
  &NCAR::cpsetr('VPB - viewport bottom',0.05);
  &NCAR::cpsetr('VPT - viewport top',0.95);
  &NCAR::pcseti('FN  - font number (Helvetica bold)' ,22);
  &NCAR::pcseti('CC  - font color',1);
  &NCAR::cpsetr('T2D - tension of 2D splines',4.);
  &NCAR::cpseti('LLP - line label positioning, penalty scheme',3);
  &NCAR::cpseti('LLO - line label orientation',1);
  &NCAR::cpsetc('LOT - low labels off',' ');
  &NCAR::cpsetr('CWM - character width multiplier',2.5);
  &NCAR::cpsetc('ILT - informational label off',' ');
  &NCAR::cprect($ZDAT,$NX,$NX,$NY,$RWRK,2000,$IWRK,1000);
#
# Initialize the area map and put the contour lines into it.
#
  &NCAR::arinam ($IAMA,20000);
  &NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
  &NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Color the map.
#
  &NCAR::arscam ($IAMA,$XCRA,$YCRA,1000,$IAIA,$IGIA,7,\&CPCOLR);
#
# Put black contour lines over the colored map.
#
  &NCAR::gsplci (1);
  &NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&NCAR::cpdrpl);
  &NCAR::cplbdr ($ZDAT,$RWRK,$IWRK);
  &NCAR::perim(1,0,1,0);
#
  &NCAR::frame();
#
#  Close down GKS.
#
  if( $ISTATE == 0 ) {
     &NCAR::gdawk ($IWKID);
     &NCAR::gclwk ($IWKID);
     &NCAR::gclks();
  }
#
}
sub CPCOLR {
  my ($XCRA,$YCRA,$NCRA,$IAIA,$IGIA,$NAIA) = @_;
#
#
  my $IFLL = 0;
  for my $I ( 1 .. $NAIA ) {
    if( at( $IGIA, $I-1 ) == 3 ) { $IFLL = at( $IAIA, $I-1 ); }
  }
  if( ( $IFLL >= 1 ) && ( $IFLL <= 8 ) ) {
    &NCAR::gsfaci ($IFLL+1);
    &NCAR::gfa ($NCRA-1,$XCRA,$YCRA);
  }
#
}

rename 'gmeta', 'ncgm/nnex03.ncgm';

