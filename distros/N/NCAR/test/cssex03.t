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
#       $Id: cssex03.f,v 1.3 2000/09/20 06:10:50 fred Exp $
#
#
#  Do a comparison of CSSGRID with NATGRIDS for interpolation on
#  a sphere, using an analytic function.  This program produces
#  four plots:
#
#     1.)  Contour plot of the analytic function.
#     2.)  Contour plot of the interpolated function using NATGRIDS
#          with no periodic points.
#     3.)  Contour plot of the interpolated function using NATGRIDS
#          with periodic points added to the longitudes.
#     4.)  Contour plot of the interpolated function using CSSGRID.
#
#  External for Conpack calls.
#
#      EXTERNAL DRAWCL;
#
#  NUMORG - Number of points in the original dataset.
#  NMAX   - Number of points in the dataset with periodic points added.
#  NUMXOUT - Number of latitudes in the interpolated dataset.
#  NUMYOUT - Number of longitudes in the interpolated dataset.
#
my ( $NUMORG, $NMAX, $NUMXOUT, $NUMYOUT ) = ( 750, 1111, 71, 145 );
my $IDIM = 2*$NUMXOUT*$NUMYOUT;
#
#  Conversion factors and constants.
#
my ( $D2R, $R2D ) = ( 0.017453293, 57.29578 );
my ( $PI, $PIH ) = ( 3.1415927, 1.5707963 );
#
#  Specify GKS output data.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 2 );
#
#  Sizes of work arrays for plotting.
#
my ( $IRWRK, $IIWRK, $IAMASZ ) = ( 5200, 11250, 20000 );
my $RWRK = zeroes float, $IRWRK;
my $IWRK = zeroes long, $IIWRK;
my $IAMA = zeroes long, $IAMASZ;
#
#  Arrays for original data.
#
my $X = zeroes float, $NMAX;
my $Y = zeroes float, $NMAX;
my $FVAL = zeroes float, $NMAX;
#
#  Arrays for output data.
#
my $RLAT = zeroes float, $NMAX;
my $RLON = zeroes float, $NMAX;
my $XI = zeroes float, $NUMXOUT;
my $YI = zeroes float, $NUMYOUT;
my $ZDAT = zeroes float, $NUMYOUT, $NUMXOUT;
my $XR = zeroes float, $NUMXOUT;
my $YR = zeroes float, $NUMYOUT;
my $FF = zeroes float, $NUMXOUT, $NUMYOUT;
my $FFN = zeroes float, $NUMXOUT, $NUMYOUT;
my $FFS = zeroes float, $NUMXOUT, $NUMYOUT;
#
#  Work arrays for CSSGRID interpolation.
#
my ( $NIWKC, $NRWKC ) = ( 27*$NMAX, 13*$NMAX );
my $IWKC = zeroes long, $NIWKC;
my $RWKC = zeroes double, $NRWKC; 
#
#  Array to store the values of the analytic function.
#
my $FF_ANA = zeroes float, $NUMXOUT, $NUMYOUT;
#
#  Generate a random dataset on the unit sphere.
#
my $N = $NUMORG;
open DAT, "<data/cssex03.dat";
my @t;
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split /\s+/, $t;
}
close DAT;
for my $I ( 1 .. $NMAX ) {
  set( $RLAT, $I-1, shift( @t ) );
}
for my $I ( 1 .. $NMAX ) {
  set( $RLON, $I-1, shift( @t ) );
}
for my $I ( 1 .. $NMAX ) {
  set( $FVAL, $I-1, shift( @t ) );
}
for my $J ( 1 .. $NUMYOUT ) {
  for my $I ( 1 .. $NUMXOUT ) {
    set( $FF_ANA, $I-1, $J-1, shift( @t ) );
  }
}
#
#  Convert to radians for NATGRIDS calls.
#
for my $K ( 1 .. $N ) {
  set( $X, $K-1, $D2R * at( $RLAT, $K-1 ) ); 
  set( $Y, $K-1, $D2R * at( $RLON, $K-1 ) ); 
}
#
#  Create the output grid.
#
for my $I ( 1 .. $NUMXOUT ) {
  my $xi = -87.5+($I-1)*2.5;
  set( $XI, $I-1, $xi );
  set( $XR, $I-1, $D2R*$xi );
}
for my $J ( 1 .. $NUMYOUT ) {
  my $yi = -180.+($J-1)*2.5;
  set( $YI, $J-1, $yi );
  set( $YR, $J-1, $D2R*$yi );
}
#
#  Use Natgrid to interpolate, without using any periodic points
#  in longitude.  There are significant problems along the zero 
#  longitude.
#
&NCAR::natgrids($N,$X,$Y,$FVAL,$NUMXOUT,$NUMYOUT,$XR,$YR,$FFN,my $IER);
#
#  Add in periodic points in longitude for the Natgrid call.
#
my $IJ = $NUMORG;
for my $I ( 1 .. $N ) {
  if( ( at( $Y, $I-1 ) > $PIH ) && ( at( $Y, $I-1 ) < $PI ) ) {
    $IJ = $IJ+1;
    set( $X, $IJ-1, at( $X, $I-1 ) );
    set( $Y, $IJ-1, at( $Y, $I-1 )-2.0*$PI );
    set( $FVAL, $IJ-1, at( $FVAL, $I-1 ) );
  } elsif( ( at( $Y, $I-1 ) >= -$PI ) && ( at( $Y, $I-1 ) < -$PIH ) ) {
    $IJ = $IJ+1;
    set( $X, $IJ-1, at( $X, $I-1 ) );
    set( $Y, $IJ-1, at( $Y, $I-1 )+2.0*$PI );
    set( $FVAL, $IJ-1, at( $FVAL, $I-1 ) );
  }
}
#
#  Use Natgrid to interpolate, using the additional periodic points.
#  
$N = $NMAX;
&NCAR::natgrids($N,$X,$Y,$FVAL,$NUMXOUT,$NUMYOUT,$XR,$YR,$FF,my $IER);
#
#  Use Cssgrid to interpolate on the sphere.
#
$N = $NUMORG;
&NCAR::cssgrid($N,$RLAT,$RLON,$FVAL,$NUMXOUT,$NUMYOUT,$XI,$YI,$FFS,$IWKC,$RWKC,my $IER);
#
#  Plot the results.
#
#
#  Open GKS.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
#  Color table.
#
&NCAR::gscr($IWKID,0,1.,1.,1.);
&NCAR::gscr($IWKID,1,0.,0.,0.);
&NCAR::gscr($IWKID,2,1.,0.,0.);
&NCAR::gscr($IWKID,3,0.,0.,1.);
#
#  Draw a contour map of the analytic function.
#
&NCAR::gsplci(3);
&NCAR::gstxci(3);
&NCAR::gstxfp(-13,2);
#
#  Use a satellite projection and view the globe looking at the
#  north pole.
#
&NCAR::mapstr ('SA - SATELLITE HEIGHT',4.);
&NCAR::maproj ('SV - SATELLITE-VIEW',90.,0.,0.);
&NCAR::mapset ('MA - MAXIMAL AREA',
                float( [ 0., 0. ] ),
                float( [ 0., 0. ] ),
                float( [ 0., 0. ] ),
                float( [ 0., 0. ] )
	       );
&NCAR::mappos (0.06, 0.94, 0.02, 0.90);
#
&NCAR::mapsti ('PE - PERIMETER',0);
&NCAR::mapsti ('GR - GRID',0);
&NCAR::mapstc ('OU - OUTLINE DATASET','PS');
&NCAR::mapsti ('DO - DOTTING OF OUTLINES',1);
&NCAR::mapdrw();
#
&NCAR::cpseti ('SET - DO SET-CALL FLAG',0);
&NCAR::cpsetr ('DPS - LINE LABEL SIZE',0.02);
&NCAR::cpsetr ('T2D - TENSION ON THE 2D SPLINES',1.);
&NCAR::cpseti ('CLS - CONTOUR LEVEL SELECTION FLAG',16);
&NCAR::cpsetc ('HLT - TURN OFF HIGH/LOW LABELS',' ');
&NCAR::cpsetc ('ILT - TURN OFF INFORMATIONAL LABEL',' ');
#
&NCAR::cpsetr ('XC1 - X COORDINATE AT I = 1',-180.);
&NCAR::cpsetr ('XCM - X COORDINATE AT I = M', 180.);
&NCAR::cpsetr ('YC1 - Y COORDINATE AT J = 1', -90.);
&NCAR::cpsetr ('YCN - Y COORDINATE AT J = N',  90.);
&NCAR::cpseti ('MAP - MAPPING FLAG',1);
&NCAR::cpsetr ('ORV - OUT-OF-RANGE VALUE',1.E12);
#
#  Reverse the indices, since Conpack wants longitude as
#  the first dimension.
#
for my $I ( 1 .. $NUMXOUT ) {
  for my $J ( 1 .. $NUMYOUT ) {
    set( $ZDAT, $J-1, $I-1, at( $FF_ANA, $I-1, $J-1 ) );
  }
}
#
&NCAR::cprect ($ZDAT,$NUMYOUT,$NUMYOUT,$NUMXOUT,$RWRK,$IRWRK,$IWRK,$IIWRK);
&NCAR::arinam ($IAMA,$IAMASZ);
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&DRAWCL);
#
#  Plot the picture title.
#
&NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plchhq(0.50,0.95,':F26:Analytic function',0.025,0.,0.);
#
&NCAR::frame();
#
#  Plot the results from Natgrid without periodic points.
#
&NCAR::mappos (0.06, 0.94, 0.02, 0.90);
&NCAR::mapdrw();
#
#  Reverse the indices, since Conpack wants longitude as
#  the first dimension.
#
for my $I ( 1 .. $NUMXOUT ) {
  for my $J ( 1 .. $NUMYOUT ) {
    set( $ZDAT, $J-1, $I-1, at( $FFN, $I-1, $J-1 ) );
  }
}
#
&NCAR::cprect ($ZDAT,$NUMYOUT,$NUMYOUT,$NUMXOUT,$RWRK,$IRWRK,$IWRK,$IIWRK);
&NCAR::arinam ($IAMA,$IAMASZ);
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&DRAWCL);
#
#  Plot the picture title.
#
&NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plchhq(0.50,0.95,':F26:Natgrid without periodic points',0.025,0.,0.);
#
&NCAR::frame();
#
#  Plot the results from Natgrid with periodic points.
#
&NCAR::mappos (0.06, 0.94, 0.02, 0.90);
&NCAR::mapdrw();
#
#  Reverse the indices, since Conpack wants longitude as
#  the first dimension.
#
for my $I ( 1 .. $NUMXOUT ) {
  for my $J ( 1 .. $NUMYOUT ) {
    set( $ZDAT, $J-1, $I-1, at( $FF, $I-1, $J-1 ) );
  }
}
#
&NCAR::cprect ($ZDAT,$NUMYOUT,$NUMYOUT,$NUMXOUT,$RWRK,$IRWRK,$IWRK,$IIWRK);
&NCAR::arinam ($IAMA,$IAMASZ);
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&DRAWCL);
#
#  Plot the picture title.
#
&NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plchhq(0.50,0.95,':F26:Natgrid with periodic points',0.025,0.,0.);
#
&NCAR::frame();
#
#  Plot the results from Cssgrid.
#
&NCAR::mappos (0.06, 0.94, 0.02, 0.90);
&NCAR::mapdrw();
#
#  Reverse the indices, since Conpack wants longitude as
#  the first dimension.
#
for my $I ( 1 .. $NUMXOUT ) {
  for my $J ( 1 .. $NUMYOUT ) {
    set( $ZDAT, $J-1, $I-1, at( $FFS, $I-1, $J-1 ) );
  }
}
#
&NCAR::cprect ($ZDAT,$NUMYOUT,$NUMYOUT,$NUMXOUT,$RWRK,$IRWRK,$IWRK,$IIWRK);
&NCAR::arinam ($IAMA,$IAMASZ);
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&DRAWCL);
#
#  Plot the picture title.
#
&NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plchhq(0.50,0.95,':F26:Cssgrid',0.025,0.,0.);
#
&NCAR::frame();
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
# 
sub DRAWCL {
  my ($XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
#
  my $IDR = 1;
  for my $I ( 1 .. $NAI ) {
    if( at( $IAI, $I-1 ) < 0 ) { $IDR = 0; }
  }
  if( $IDR != 0 ) { &NCAR::curved( $XCS,$YCS,$NCS ); }
#
}

rename 'gmeta', 'ncgm/cssex03.ncgm';

