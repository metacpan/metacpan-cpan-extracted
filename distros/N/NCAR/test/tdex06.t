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
# This example shows how a user can directly generate the list of
# triangles defining a surface and then render the surface using
# TDPACK routines.
#
# Consider the surface defined by the following equations (for values
# of u and v between 0 and 2 pi).
#
#     R (A,U,V) = A * [ COS(U) + COS(U-V) ] + B
#   PHI (A,U,V) = V
#     Z (A,U,V) = A * [ SIN(U) + SIN(U-V) ]
#
# where R, PHI, and Z are the usual cylindrical coordinates (radius,
# angle, and height).
#
# 0 < A < 1 is the range of interest and B is any convenient value
# greater than A.
#
# Define A, B, and the sum of the two for scaling.
#
my ( $A, $B ) = ( 1, 3 );
my ( $BMIN, $BMAX ) = ( - $A - $B, $A + $B );
#
# Define a parameter specifying the maximum size of the array required
# for the list of triangles.
#
my $MTRI=100000;
#
# Define values of pi, two times pi, and pi over 180.
#
my $PI = 3.14159265358979323846;
my $TWOPI = 2*$PI;
my $DTOR = $PI/180;
#
# Declare a local array to hold the triangle list and a couple of
# temporary variables to be used in sorting the list.
#
my $RTRI = zeroes float, 10, $MTRI;
my $RTWK = zeroes float, 2, $MTRI;
my $ITWK = zeroes long, $MTRI;
#
# Set the desired minimum and maximum values of U and V (for the grid
# over which the surface is generated).
#
my ( $UMIN, $UMAX ) = ( 0., $TWOPI );
my ( $VMIN, $VMAX ) = ( 0., $TWOPI );
#
# Set the desired minimum and maximum values of X, Y, and Z.
#
my ( $XMIN, $XMAX ) = ( $BMIN, $BMAX );
my ( $YMIN, $YMAX ) = ( $BMIN, $BMAX );
my ( $ZMIN, $ZMAX ) = ( $BMIN, $BMAX );
#
# Set the values determining the resolution of the grid over which the
# surface is generated.  Note that, if each of IDIM and JDIM is one more
# than a multiple of 12, the assignment of rendering styles works out
# best.
#
my ( $IDIM, $JDIM ) = ( 109, 109 );
#
# Set the desired values of parameters determining the eye position.
# ANG1 is a bearing angle, ANG2 is an elevation angle, and RMUL is a
# multiplier of the length of the diagonal of the data box, specifying
# the distance from the center of the box to the eye.
#
my ( $ANG1, $ANG2, $RMUL ) = ( 215., 35., 2.9 );
#
# ISTE is a flag that says whether to do a simple image (ISTE=0),
# a one-frame stereo image (ISTE=-1), or a two-frame stereo image
# (ISTE=+1).
#
my $ISTE = -1;
#
# ASTE is the desired angle (in degrees) between the lines of sight for
# a pair of stereo views.
#
my $ASTE = 4.;
#
# WOSW is the width of the stereo windows to be used in one-frame stereo
# images; the width is stated as a fraction of the width of the plotter
# frame.  (The windows are centered vertically; horizontally, they are
# placed as far apart as possible in the plotter frame.)  The value used
# must be positive and non-zero; it may be slightly greater than .5, if
# it is desired that the stereo windows should overlap slightly.
#
my $WOSW = .5;
#
# Set the desired value of the flag that says whether the basic color
# scheme will be white on black (IBOW=0) or black on white (IBOW=1).
#
my $IBOW = 1;
#
# Set the desired value of the flag that says whether shading of the
# surfaces will be done using gray scales (ICLR=0) or colors (ICLR=1).
#
my $ICLR = 1;
#
# Set the desired values of the shading parameters.  Values of SHDE
# near 0 give brighter colors and values near 1 give pastel shades.
# Values of SHDR near 0 give a narrow range of shades and values near
# 1 give a wide range of shades.
#
my ( $SHDE, $SHDR ) = ( .1, .8 );
#
# Define labels for the edges of the box.
#
my $XNLB = ' -4 -3 -2 -1 0 1 2 3 4 ';
my $YNLB = ' -4 -3 -2 -1 0 1 2 3 4 ';
my $ZNLB = ' -4 -3 -2 -1 0 1 2 3 4 ';
#
my $XILB = 'X Coordinate Values';
my $YILB = 'Y Coordinate Values';
my $ZILB = 'Z Coordinate Values';
#
# Define arithmetic statement functions for r, phi, and h as functions
# of U and V.
#
sub RVAL {
  my ( $U, $V ) = @_;
  return $A*(cos($U)+cos($U-$V))+$B;
}
sub PVAL {
  my ( $U, $V ) = @_;
  return $V;
}
sub HVAL {
  my ( $U, $V ) = @_;
  return $A*(sin($U)+sin($U-$V));
}
#
# Define arithmetic statement functions to transform cylindrical
# coordinates into Cartesian coordinates.
#
sub XVAL {
  my ( $R, $P, $H ) = @_;
  return $R*cos($P);
}
sub YVAL {
  my ( $R, $P, $H ) = @_;
  return $R*sin($P);
}
sub ZVAL {
  my ( $R, $P, $H ) = @_;
  return $H;
}
#
# Open GKS.
#
&NCAR::opngks();
#
# Turn clipping off.
#
&NCAR::gsclip (0);
#
# Double the line width.
#
&NCAR::gslwsc (2.);
#
# Define colors to use.
#
&NCAR::tdclrs (1,$IBOW,$SHDE,$SHDR,11,26,8);
#
# Select font number 25, turn on the outlining of filled fonts, set the
# line width to 1, and turn off the setting of the outline color.
#
&NCAR::pcseti ('FN - FONT NUMBER',25);
&NCAR::pcseti ('OF - OUTLINE FLAG',1);
&NCAR::pcsetr ('OL - OUTLINE LINE WIDTH',1.);
&NCAR::pcsetr ('OC - OUTLINE LINE COLOR',-1.);
#
# Make TDPACK characters a bit bigger.
#
&NCAR::tdsetr ('CS1',1.25);
#
# Define TDPACK rendering styles 1 through 7, using black-and-white
# shading or colored shading, whichever is selected.  The indices
# 1-7 can then be used as final arguments in calls to TDITRI, TDSTRI,
# and TDMTRI.
#
if( $ICLR == 0 ) {
&NCAR::tdstrs (1,27,42, 27, 42,-1,-1,1,0.,0.,0.) # gray/gray;
&NCAR::tdstrs (2,27,42, 27, 42,-1,-1,1,0.,0.,0.) # gray/gray;
&NCAR::tdstrs (3,27,42, 27, 42,-1,-1,1,0.,0.,0.) # gray/gray;
&NCAR::tdstrs (4,27,42, 27, 42,-1,-1,1,0.,0.,0.) # gray/gray;
&NCAR::tdstrs (5,27,42, 27, 42,-1,-1,1,0.,0.,0.) # gray/gray;
&NCAR::tdstrs (6,27,42, 27, 42,-1,-1,1,0.,0.,0.) # gray/gray;
&NCAR::tdstrs (7,27,42, 27, 42,-1,-1,1,0.,0.,0.) # gray/gray;
} else {
&NCAR::tdstrs (1,27,42, 27, 42,-1,-1,1,0.,0.,0.) # gray/gray;
&NCAR::tdstrs (2,27,42, 43, 58,-1,-1,1,0.,0.,0.) # gray/red;
&NCAR::tdstrs (3,27,42, 59, 74,-1,-1,1,0.,0.,0.) # gray/green;
&NCAR::tdstrs (4,27,42, 75, 90,-1,-1,1,0.,0.,0.) # gray/blue;
&NCAR::tdstrs (5,27,42, 91,106,-1,-1,1,0.,0.,0.) # gray/cyan;
&NCAR::tdstrs (6,27,42,107,122,-1,-1,1,0.,0.,0.) # gray/magenta;
&NCAR::tdstrs (7,27,42,123,138,-1,-1,1,0.,0.,0.) # gray/yellow;
}
#
# Initialize the count of triangles in the triangle list.
#
my $NTRI=0;
#
# For each box on a rectangular grid in the UV plane, generate two
# triangles and add them to the triangle list.  Each triangle is
# transformed from cylindrical coordinates to Cartesian coordinates.
# The rendering style is made a function of the U coordinate; try
# uncommenting the second expression for ISRS to see what happens
# when the rendering style is made a function of the V coordinate.
#
for my $I ( 1 .. $IDIM-1 ) {
  my $UVMI=$UMIN+(($I-1)/($IDIM-1))*($UMAX-$UMIN);
  my $UVMA=$UMIN+(($I  )/($IDIM-1))*($UMAX-$UMIN);
  my $IURS=&NCAR::Test::max(1,&NCAR::Test::min(12,1+int(12.*(($UVMI+$UVMA)/2.-$UMIN)/($UMAX-$UMIN))));
  for my $J ( 1 .. $JDIM-1 ) {
    my $VVMI=$VMIN+(($J-1)/($JDIM-1))*($VMAX-$VMIN);
    my $VVMA=$VMIN+(($J  )/($JDIM-1))*($VMAX-$VMIN);
    my $IVRS=&NCAR::Test::max(1,&NCAR::Test::min(12,1+int(12.*(($VVMI+$VVMA)/2.-$VMIN)/($VMAX-$VMIN))));
    my $ISRS=(($IURS-1)%3)+2;
#           ISRS=MOD(       IVRS-1,3)+2
#           ISRS=MOD(IURS-1+IVRS-1,3)+2
    my $RV00 = &RVAL( $UVMI, $VVMI );
    my $PV00 = &PVAL( $UVMI, $VVMI );
    my $HV00 = &HVAL( $UVMI, $VVMI );
    my $RV01 = &RVAL( $UVMI, $VVMA );
    my $PV01 = &PVAL( $UVMI, $VVMA );
    my $HV01 = &HVAL( $UVMI, $VVMA );
    my $RV10 = &RVAL( $UVMA, $VVMI );
    my $PV10 = &PVAL( $UVMA, $VVMI );
    my $HV10 = &HVAL( $UVMA, $VVMI );
    my $RV11 = &RVAL( $UVMA, $VVMA );
    my $PV11 = &PVAL( $UVMA, $VVMA );
    my $HV11 = &HVAL( $UVMA, $VVMA );
    if( $NTRI < $MTRI ) {
      $NTRI=$NTRI+1;
      set( $RTRI, 1-1, $NTRI, &XVAL( $RV10, $PV10, $HV10) );
      set( $RTRI, 2-1, $NTRI, &YVAL( $RV10, $PV10, $HV10) );
      set( $RTRI, 3-1, $NTRI, &ZVAL( $RV10, $PV10, $HV10) );
      set( $RTRI, 4-1, $NTRI, &XVAL( $RV00, $PV00, $HV00) );
      set( $RTRI, 5-1, $NTRI, &YVAL( $RV00, $PV00, $HV00) );
      set( $RTRI, 6-1, $NTRI, &ZVAL( $RV00, $PV00, $HV00) );
      set( $RTRI, 7-1, $NTRI, &XVAL( $RV01, $PV01, $HV01) );
      set( $RTRI, 8-1, $NTRI, &YVAL( $RV01, $PV01, $HV01) );
      set( $RTRI, 9-1, $NTRI, &ZVAL( $RV01, $PV01, $HV01) );
      set( $RTRI,10-1, $NTRI, $ISRS );
    }
    if( $NTRI < $MTRI ) {
      $NTRI=$NTRI+1;
      set( $RTRI, 1-1, $NTRI, &XVAL( $RV01, $PV01, $HV01 ) );
      set( $RTRI, 2-1, $NTRI, &YVAL( $RV01, $PV01, $HV01 ) );
      set( $RTRI, 3-1, $NTRI, &ZVAL( $RV01, $PV01, $HV01 ) );
      set( $RTRI, 4-1, $NTRI, &XVAL( $RV11, $PV11, $HV11 ) );
      set( $RTRI, 5-1, $NTRI, &YVAL( $RV11, $PV11, $HV11 ) );
      set( $RTRI, 6-1, $NTRI, &ZVAL( $RV11, $PV11, $HV11 ) );
      set( $RTRI, 7-1, $NTRI, &XVAL( $RV10, $PV10, $HV10 ) );
      set( $RTRI, 8-1, $NTRI, &YVAL( $RV10, $PV10, $HV10 ) );
      set( $RTRI, 9-1, $NTRI, &ZVAL( $RV10, $PV10, $HV10 ) );
      set( $RTRI,10-1, $NTRI, $ISRS );
    }
  }
}
#
# Find the midpoint of the data box (to be used as the point looked at).
#
my $XMID=.5*($XMIN+$XMAX);
my $YMID=.5*($YMIN+$YMAX);
my $ZMID=.5*($ZMIN+$ZMAX);
#
# Determine the distance (R) from which the data box will be viewed and,
# given that, the eye position.
#
my $R=$RMUL*sqrt(($XMAX-$XMIN)*($XMAX-$XMIN)
                +($YMAX-$YMIN)*($YMAX-$YMIN)
                +($ZMAX-$ZMIN)*($ZMAX-$ZMIN));
#
my $XEYE=$XMID+$R*cos($DTOR*$ANG1)*cos($DTOR*$ANG2);
my $YEYE=$YMID+$R*sin($DTOR*$ANG1)*cos($DTOR*$ANG2);
my $ZEYE=$ZMID+$R*sin($DTOR*$ANG2);
#
# Initialize the stereo offset argument to do either a single view or
# a left-eye view (whichever is selected by the value of ISTE).
#

sub Tan {
  my $x = shift;
  return sin( $x ) / cos( $x );
}

my $OTEP;

if( $ISTE == 0 ) {
  $OTEP=0.;                          #  (single view);
} else {
  $OTEP=-$R * &Tan($DTOR*$ASTE/2.);  #  (left-eye view);
}
#
# Initialize TDPACK.
#
L109:
&NCAR::tdinit ($XEYE,$YEYE,$ZEYE,$XMID,$YMID,$ZMID,$XMID,$YMID,$ZMID+$R,$OTEP);
#
# If stereo views are being done, do the requested thing, either by
# redoing the SET call to put them side by side on the same frame,
# or by calling FRAME to put them on separate frames.
#
if( $OTEP != 0 ) {
  if( $ISTE < 0 ) {
    &NCAR::getset ( my ( $XVPL,$XVPR,$YVPB,$YVPT,$XWDL,$XWDR,$YWDB,$YWDT,$LNLG ) );
    if( $OTEP < 0 ) {
      &NCAR::set  (1.-$WOSW,1.,.5-.5*$WOSW,.5+.5*$WOSW,$XWDL,$XWDR,$YWDB,$YWDT,$LNLG);
    } else {
      &NCAR::set  (  0., $WOSW,.5-.5*$WOSW,.5+.5*$WOSW,$XWDL,$XWDR,$YWDB,$YWDT,$LNLG);
    }
  } else {
    if( $OTEP > 0 ) { &NCAR::frame(); }
  }
}
#
# Order the triangles in the triangle list.
#
&NCAR::tdotri ($RTRI,$MTRI,$NTRI,$RTWK,$ITWK,1);
#
if( $NTRI == $MTRI ) {
  print STDERR "
TRIANGLE LIST OVERFLOW IN TDOTRI
";
  exit( 0 );
}
#
# Draw labels for the axes.
#
&NCAR::tdlbls ($XMIN,$YMIN,$ZMIN,$XMAX,$YMAX,$ZMAX,$XNLB,$YNLB,$ZNLB,$XILB,$YILB,$ZILB,1);
#
# Draw the sides of the box that could be hidden.
#
&NCAR::tdgrds ($XMIN,$YMIN,$ZMIN,$XMAX,$YMAX,$ZMAX,
               .1*($XMAX-$XMIN),.1*($YMAX-$YMIN),.1*($ZMAX-$ZMIN),12,1);
#
# Draw the triangles in the triangle list.
#
&NCAR::tddtri ($RTRI,$MTRI,$NTRI,$ITWK);
#
# Draw the sides of the box that could not be hidden.
#
&NCAR::tdgrds ($XMIN,$YMIN,$ZMIN,$XMAX,$YMAX,$ZMAX,
               .1*($XMAX-$XMIN),.1*($YMAX-$YMIN),.1*($ZMAX-$ZMIN),12,0);
#
# If a left-eye view has just been done, loop back for a right-eye view.
#
if( $OTEP < 0 ) {
  $OTEP = - $OTEP;
  goto L109;
}
#
# Advance the frame.
#
&NCAR::frame();
#
# Close GKS.
#
&NCAR::clsgks();
#
# Done.
#


rename 'gmeta', 'ncgm/tdex06.ncgm';
