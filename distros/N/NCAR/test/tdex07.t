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
use NCAR::Test;  ;

#
# Create parameters specifying the maximum sizes of the arrays defining
# data, the arrays required for dealing with the list of triangles, and
# the arrays of points defining a curve.
#
my ( $IMAX, $JMAX, $KMAX, $MTRI, $NCRA ) 
 = ( 41, 41, 41, 200000, 1001 );
#
# Declare local dimensioned variables to hold data defining a simple
# surface and an isosurface.
#
my $U = zeroes float, $IMAX;
my $V = zeroes float, $JMAX;
my $W = zeroes float, $KMAX;
my $S = zeroes float, $JMAX, $IMAX;
my $F = zeroes float, $KMAX, $JMAX, $IMAX;
#
# Declare a local array to hold the triangle list and a couple of
# temporary variables to be used in sorting the list.
#
my $RTRI = zeroes float, $MTRI, 10;
my $RTWK = zeroes float, 2, $MTRI;
my $ITWK = zeroes long, $MTRI;
#
# Declare variables to hold the coordinates of points defining a curve.
#
my $UCRA = zeroes float, $NCRA;
my $VCRA = zeroes float, $NCRA;
my $WCRA = zeroes float, $NCRA;
#
# Set the desired minimum and maximum values of U, V, and W.
#
my ( $UMIN, $VMIN, $WMIN, $UMAX, $VMAX, $WMAX ) = ( -1.,-1.,-1.,1.,1.,1. );
#
# Set the desired values of the dimensions of the data arrays.  Note
# that IDIM must not exceed IMAX, that JDIM must not exceed JMAX, and
# that KDIM must not exceed KMAX.
#
my ( $IDIM, $JDIM, $KDIM ) = ( 31,31,31 );
#
# Set the desired values of parameters determining the eye position.
# ANG1 is a bearing angle, ANG2 is an elevation angle, and RMUL is a
# multiplier of the length of the diagonal of the data box, specifying
# the distance from the center of the box to the eye.
#
my ( $ANG1, $ANG2, $RMUL ) =( -35.,25.,2.9 );
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
my ( $SHDE, $SHDR ) =( .1 , .8 );
#
# Set the desired values of the rendering-style indices for the
# isosurface and the simple surface, respectively.
#
my ( $IIRS, $ISRS ) = ( 2, 3 );
#
# Define the conversion constant from degrees to radians.
#
my $DTOR = .017453292519943;
#
# Define labels for the edges of the box.
#
my $UNLB = ' -1 -.8 -.6 -.4 -.2 0 .2 .4 .6 .8 1 ';
my $VNLB = ' -1 -.8 -.6 -.4 -.2 0 .2 .4 .6 .8 1 ';
my $WNLB = ' -1 -.8 -.6 -.4 -.2 0 .2 .4 .6 .8 1 ';
#
my $UILB = 'U Coordinate Values';
my $VILB = 'V Coordinate Values';
my $WILB = 'W Coordinate Values';
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
&NCAR::tdclrs (1,$IBOW,$SHDE,$SHDR,11,42,5);
#
# Fill data arrays defining a simple surface and an isosurface.  The
# simple surface is defined by the equation "w=s(u,v)"; the function
# "s" is approximated by the contents of the array S: S(I,J) is the
# value of s(U(I),V(J)), where I goes from 1 to IDIM and J from 1 to
# JDIM.  The isosurface is defined by the equation f(u,v,w)=1.; the
# function f is approximated by the contents of the array F: F(I,J,K)
# is the value of f(U(I),V(J),W(K)), where I goes from 1 to IDIM, J
# from 1 to JDIM, and K from 1 to KDIM.
#
for my $I ( 1 .. $IDIM ) {
  set( $U, $I-1, $UMIN + ($I-1)/($IDIM-1)*($UMAX-$UMIN) );
}
#
for my $J ( 1 .. $JDIM ) {
  set( $V, $J-1, $VMIN + ($J-1)/($JDIM-1)*($VMAX-$VMIN) );
}
#
for my $K ( 1 .. $KDIM ) {
  set( $W, $K-1, $WMIN + ($K-1)/($KDIM-1)*($WMAX-$WMIN) );
}
#
for my $I ( 1 .. $IDIM ) {
  my $U2 = at( $U, $I-1 )*at( $U, $I-1 );
  for my $J ( 1 .. $JDIM ) {
    my $V2 = at( $V, $J-1 )*at( $V, $J-1 );
    set( $S, $J-1, $I-1, 2.*exp(-4.*($U2+$V2))-1. );
    for my $K ( 1 .. $KDIM ) {
      my $W2 = at( $W, $K-1 )*at( $W, $K-1 );
      set( $F, $K-1, $J-1, $I-1, 1.25*$U2+3.0*$V2+5.*$W2 );
    }
  }
}
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
# 1-7 can then be used as arguments in calls to TDITRI, TDSTRI, and
# TDMTRI.
#
if( $ICLR == 0 ) {
&NCAR::tdstrs (1,43,74, 43, 74,-1,-1,1,0.,0.,0.) # gray/gray;
&NCAR::tdstrs (2,43,74, 43, 74,-1,-1,1,0.,0.,0.) # gray/gray;
&NCAR::tdstrs (3,43,74, 43, 74,-1,-1,1,0.,0.,0.) # gray/gray;
&NCAR::tdstrs (4,43,74, 43, 74,-1,-1,1,0.,0.,0.) # gray/gray;
&NCAR::tdstrs (5,43,74, 43, 74,-1,-1,1,0.,0.,0.) # gray/gray;
&NCAR::tdstrs (6,43,74, 43, 74,-1,-1,1,0.,0.,0.) # gray/gray;
&NCAR::tdstrs (7,43,74, 43, 74,-1,-1,1,0.,0.,0.) # gray/gray;
} else {
&NCAR::tdstrs (1,43,74, 43, 74,-1,-1,1,0.,0.,0.) # gray/gray;
&NCAR::tdstrs (2,43,74, 75,106,-1,-1,1,0.,0.,0.) # gray/red;
&NCAR::tdstrs (3,43,74,107,138,-1,-1,1,0.,0.,0.) # gray/green;
&NCAR::tdstrs (4,43,74,139,170,-1,-1,1,0.,0.,0.) # gray/blue;
&NCAR::tdstrs (5,43,74,171,202,-1,-1,1,0.,0.,0.) # gray/cyan;
&NCAR::tdstrs (6,43,74,203,234,-1,-1,1,0.,0.,0.) # gray/magenta;
&NCAR::tdstrs (7,43,74,235,266,-1,-1,1,0.,0.,0.) # gray/yellow;
}
#
# Initialize the count of triangles in the triangle list.
#
my $NTRI=0;
#
# Add to the triangle list triangles representing a simple surface.
#
&NCAR::tdstri ($U,$IDIM,$V,$JDIM,$S,$IMAX,$RTRI,$MTRI,$NTRI,$ISRS);
#
if( $NTRI == $MTRI ) {
  print STDERR "
TRIANGLE LIST OVERFLOW IN TDSTRI
";
  exit( 0 );
}
#
# Add to the triangle list triangles representing an isosurface.
#
&NCAR::tditri ($U,$IDIM,$V,$JDIM,$W,$KDIM,$F,$IMAX,$JMAX,1.,$RTRI,$MTRI,$NTRI,$IIRS);
#
if( $NTRI == $MTRI ) {
  print STDERR "
TRIANGLE LIST OVERFLOW IN TDITRI
";
  exit( 0 );
}
#
# Add to the triangle list triangles representing a series of marks
# along a curve.
#
for my $ICRA ( 1 .. $NCRA ) {
  my $TEMP=($ICRA-1)/($NCRA-1);
  my $RADI=(&NCAR::Test::min($UMAX-$UMIN,$VMAX-$VMIN)/2.)*(.75+($TEMP-.5)*($TEMP-.5));
  my $ANGD=720.*$TEMP;
  set( $UCRA, $ICRA-1, ($UMIN+$UMAX)/2.+$RADI*cos(.017453292519943*$ANGD) );
  set( $VCRA, $ICRA-1, ($VMIN+$VMAX)/2.+$RADI*sin(.017453292519943*$ANGD) );
  set( $WCRA, $ICRA-1, $WMIN+$TEMP*($WMAX-$WMIN) );
}
#
my $RMRK=&NCAR::Test::min($UMAX-$UMIN,$VMAX-$VMIN,$WMAX-$WMIN)/50.;
#

&NCAR::tdttri ($UCRA,$VCRA,$WCRA,$NCRA,5,$RMRK,$RMRK/8.,$RTRI,$MTRI,$NTRI,4,
               $UMIN,$VMIN,$WMIN,$UMAX,$VMAX,$WMAX);

#
# Find the midpoint of the data box (to be used as the point looked at).
#
my $UMID=.5*($UMIN+$UMAX);
my $VMID=.5*($VMIN+$VMAX);
my $WMID=.5*($WMIN+$WMAX);
#
# Determine the distance (R) from which the data box will be viewed and,
# given that, the eye position.
#
my $R=$RMUL*sqrt(($UMAX-$UMIN)*($UMAX-$UMIN)
                +($VMAX-$VMIN)*($VMAX-$VMIN)
                +($WMAX-$WMIN)*($WMAX-$WMIN));
#
my $UEYE=$UMID+$R*cos($DTOR*$ANG1)*cos($DTOR*$ANG2);
my $VEYE=$VMID+$R*sin($DTOR*$ANG1)*cos($DTOR*$ANG2);
my $WEYE=$WMID+$R*sin($DTOR*$ANG2);
#
# Initialize the stereo offset argument to do either a single view or
# a left-eye view (whichever is selected by the value of ISTE).
#
sub Tan {
  my $x = shift;
  return sin( $x ) / cos( $x );
}

if( $ISTE == 0 ) {
  $OTEP=0.;                        #  (single view);
} else {
  $OTEP=-$R*&Tan($DTOR*$ASTE/2.);  #  (left-eye view);
}
#
# Initialize TDPACK.
#
L109:
&NCAR::tdinit($UEYE,$VEYE,$WEYE,$UMID,$VMID,$WMID,$UMID,$VMID,$WMID+$R,$OTEP);
#
# If stereo views are being done, do the requested thing, either by
# redoing the SET call to put them side by side on the same frame,
# or by calling FRAME to put them on separate frames.
#
if( $OTEP != 0 ) {
  if( $ISTE > 0 ) {
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
  exit(0);
}
#
# Draw labels for the axes.
#
&NCAR::tdlbls ($UMIN,$VMIN,$WMIN,$UMAX,$VMAX,$WMAX,$UNLB,$VNLB,$WNLB,$UILB,$VILB,$WILB,1);
#
# Draw the sides of the box that could be hidden.
#
&NCAR::tdgrds ($UMIN,$VMIN,$WMIN,$UMAX,$VMAX,$WMAX,
               .1*($UMAX-$UMIN),.1*($VMAX-$VMIN),.1*($WMAX-$WMIN),12,1);
#
# Draw the triangles in the triangle list.
#
&NCAR::tddtri ($RTRI,$MTRI,$NTRI,$ITWK);
#
# Draw the sides of the box that could not be hidden.
#
&NCAR::tdgrds ($UMIN,$VMIN,$WMIN,$UMAX,$VMAX,$WMAX,
               .1*($UMAX-$UMIN),.1*($VMAX-$VMIN),.1*($WMAX-$WMIN),12,0);
#
# If a left-eye view has just been done, loop back for a right-eye view.
#
if( $OTEP < 0 ) {
  $OTEP=-$OTEP;
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


rename 'gmeta', 'ncgm/tdex07.ncgm';
