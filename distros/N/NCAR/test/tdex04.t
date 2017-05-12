# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

BEGIN { $| = 1; print "1..1\n"; };
END {print "not ok 1\n" unless $loaded;};
use NCAR;
$loaded = 1;
print "ok 1\n";

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

unlink( 'gmeta' );

use PDL;
use NCAR::Test qw( bndary gendat drawcl );
use strict;


#
# This is a modified version of the TDPACK example "tdex01".  The two
# surfaces have been modified to illustrate new capabilities.  The
# color of the simple surface ranges from blue at the bottom to red at
# the top, while the lumpy doughnut that intersects it is shown in
# yellow.  In addition, cyan lines are used to indicate selected planes
# of constant U, V, or W.
#
# Create parameters specifying the maximum sizes of the arrays defining
# data and the arrays required for dealing with the list of triangles.
#
my ( $IMAX, $JMAX, $KMAX, $MTRI ) = ( 81, 81, 81, 400000 );
#
# Set the desired values of the dimensions of the data arrays.  Note
# that IDIM must not exceed IMAX, that JDIM must not exceed JMAX, and
# that KDIM must not exceed KMAX.  NLYR is the number of vertical
# layers to be used in rendering the simple surface.  There is an
# inverse relationship between the number of layers you use for the
# surface (which determines how many different colors will be used)
# and the number of shades of those colors that you can generate.
# (The shades are used to give a visual sense of the angle between
# the line of sight and the normal to the surface.)
#
my ( $IDIM, $JDIM, $KDIM, $NLYR ) = ( 81, 81, 81, 10 );
#
# Declare local dimensioned variables to hold data defining a simple
# surface and an isosurface.
#
my $U = zeroes float, $IMAX;
my $V = zeroes float, $JMAX;
my $W = zeroes float, $KMAX;
my $S = zeroes float, $JMAX, $IMAX;
my $F = zeroes float, $IMAX, $JMAX, $KMAX;
my $Q = zeroes float, 2, $JMAX, $IMAX;
#
# Declare a local array to hold the triangle list and a couple of
# temporary variables to be used in sorting the list.
#
my $RTRI = zeroes float, 10, $MTRI;
my $RTWK = zeroes float, 2, $MTRI;
my $ITWK = zeroes long, $MTRI;
#
# Set the desired minimum and maximum values of U, V, and W.
#
my ( $UMIN,$VMIN,$WMIN,$UMAX,$VMAX,$WMAX ) = (  -1.,-1.,-1.,1.,1.,1. );
#
# Set the desired values of parameters determining the eye position.
# ANG1 is a bearing angle, ANG2 is an elevation angle, and RMUL is a
# multiplier of the length of the diagonal of the data box, specifying
# the distance from the center of the box to the eye.
#
my ( $ANG1,$ANG2,$RMUL ) = ( -35.,25.,2.9 );
#
# ISTE is a flag that says whether to do a simple image (ISTE=0),
# a one-frame stereo image (ISTE=-1), or a two-frame stereo image
# (ISTE=+1).
#
my $ISTE = -1;
#       DATA ISTE /  0 /
#       DATA ISTE / +1 /
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
# Define the limits for the cyan stripes indicating certain values of
# U, V, or W.
#
#       DATA USMN,USMX /  .44 ,  .46 /
#       DATA VSMN,VSMX / -.56 , -.54 /
#       DATA WSMN,WSMX / -.16 , -.14 /
#
my ( $USMN,$USMX ) = ( -.01 , +.01 );
my ( $VSMN,$VSMX ) = ( -.01 , +.01 );
my ( $WSMN,$WSMX ) = ( -.01 , +.01 );
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
# Define the background color and the basic foreground color.
#
if( $IBOW == 0 ) {
&NCAR::gscr (1,0,0.,0.,0.);  #  black;
&NCAR::gscr (1,1,1.,1.,1.);  #  white;
} else {
&NCAR::gscr (1,0,1.,1.,1.);  #  white;
&NCAR::gscr (1,1,0.,0.,0.);  #  black;
}
#
# Define the primary colors.
#
&NCAR::gscr   (1,2,1.,0.,0.);  #  red;
&NCAR::gscr   (1,3,0.,1.,0.);  #  green;
&NCAR::gscr   (1,4,0.,0.,1.);  #  blue;
&NCAR::gscr   (1,5,0.,1.,1.);  #  cyan;
&NCAR::gscr   (1,6,1.,0.,1.);  #  magenta;
&NCAR::gscr   (1,7,1.,1.,0.);  #  yellow;
#
# Now we need a bunch more colors.  Each of the NLYR layers of the
# simple surface is to be a different color and the isosurface is
# to be made yet another color.  Additionally, we want to vary the
# shading of each surface layer and of the isosurface as implied by
# the angle between the line of sight and the local normal.  As we
# define the colors required, we define the required rendering styles
# for TDPACK.  ILCU is the index of the last color used so far.
#
my $ILCU=7;
#
# NSHD is the largest number of shades of each color that we can
# generate.  (Note the trade-off between the number of levels and
# the number of shades at each level.  With 31 levels, we get about
# 7 shades of each color, which is not really enough.)
#
my $NSHD=int(256-($ILCU+1))/($NLYR+1);
#
# Generate NSHD shades of each of NLYR+1 colors and use them to
# create NLYR+1 different rendering styles.  Note that I have set
# up the shades to run from the brightest shade down to .2 times
# the brightest shade.  This looks pretty good to my eye, but
# others may prefer something different.
#
my ( $R, $G, $B );
for my $I ( 1 .. $NLYR+1 ) {
  if( $I <= $NLYR ) {
    $R=($I-1)/($NLYR-1);  #  From blue to red.;
    $G=0.;
    $B=1.-$R;
  } elsif( $I == ( $NLYR+1 ) ) {
    $R=1.;                #  Yellow.;
    $G=1.;
    $B=0.;
  }
  &NCAR::tdstrs ($I,1,1,$ILCU+1,$ILCU+$NSHD,-1,-1,0,0.,0.,0.);
  for my $J ( 1 .. $NSHD ) {
     $ILCU=$ILCU+1;
     my $P=($NSHD-$J+1)/($NSHD);  #  P in range (0,1].;
     &NCAR::gscr (1,$ILCU,.2+.8*$P*$R,.2+.8*$P*$G,.2+.8*$P*$B);
  }
}
#
# Define one more rendering style, for the stripes that will be used
# to mark selected planes of constant U, V, or W.  This involves only
# a single color (cyan, color index 5) because we want the stripes to
# really stand out.
#
&NCAR::tdstrs ($NLYR+2,1,1,5,5,-1,-1,0,0.,0.,0.);
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
  set( $U, $I-1, $UMIN+(($I-1)/($IDIM-1))*($UMAX-$UMIN) );
}
#
for my $J ( 1 .. $JDIM ) {
  set( $V, $J-1, $VMIN+(($J-1)/($JDIM-1))*($VMAX-$VMIN) );
}
#
for my $K ( 1 .. $KDIM ) {
  set( $W, $K-1, $WMIN+(($K-1)/($KDIM-1))*($WMAX-$WMIN) );
}
#
for my $I ( 1 .. $IDIM ) {
  my $u = at( $U, $I-1 );
  for my $J ( 1 .. $JDIM ) {
    my $v = at( $V, $J-1 );
    set( $S, $J-1, $I-1, 2.*exp(-2.*($u*$u+$v*$v))-1. );
    for my $K ( 1 .. $KDIM ) {
      my $w = at( $W, $K-1 );
      my $f = 1.25*$u*$u+1.25*$v*$v+1.25*$w*$w;
      set( $F, $I-1, $J-1, $K-1, $f*(1.75+.85*sin(90.*$DTOR+5.*atan2($v,$u))) );
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
# Initialize the count of triangles in the triangle list.
#
my $NTRI=0;
#
# Add to the triangle list triangles representing a simple surface;
# initially, use rendering style 1; later, we will examine all the
# triangles and make the rendering style for each a function of W.
#
&NCAR::tdstri ($U,$IDIM,$V,$JDIM,$S,$IMAX,$RTRI,$MTRI,$NTRI,1);
#
if( $NTRI == $MTRI ) {
  print STDERR "\nTRIANGLE LIST OVERFLOW IN TDSTRI\n";;
  exit();
}
#
# Cut all the triangles generated so far into pieces, using planes that
# cut the data box into NLYR slices perpendicular to the vertical axis.
#
my $ULYR=($UMAX-$UMIN)/($NLYR);
my $VLYR=($VMAX-$VMIN)/($NLYR);
my $WLYR=($WMAX-$WMIN)/($NLYR);
#
for my $I ( 1 .. $NLYR-1 ) {
  &NCAR::tdctri ($RTRI,$MTRI,$NTRI,3,$WMIN+$I*$WLYR);
}
#
# Now, add to the triangle list triangles representing an isosurface;
# use rendering style NLYR+1.
#
&NCAR::tditri ($U,$IDIM,$V,$JDIM,$W,$KDIM,$F,$IMAX,$JMAX,1.,$RTRI,$MTRI,$NTRI,$NLYR+1);
#
if( $NTRI == $MTRI ) {
  print STDERR "\nTRIANGLE LIST OVERFLOW IN TDITRI\n";
  exit();
}
#
# Put some more slices through the triangles, so that we can put some
# cyan stripes on the surfaces for certain values of U, V, and W.
#
if( $USMN < $USMX ) {
&NCAR::tdctri ($RTRI,$MTRI,$NTRI,1,$USMN);
&NCAR::tdctri ($RTRI,$MTRI,$NTRI,1,$USMX);
}
#
if( $VSMN < $VSMX ) {
&NCAR::tdctri ($RTRI,$MTRI,$NTRI,2,$VSMN);
&NCAR::tdctri ($RTRI,$MTRI,$NTRI,2,$VSMX);
}
#
if( $WSMN < $WSMX ) {
&NCAR::tdctri ($RTRI,$MTRI,$NTRI,3,$WSMN);
&NCAR::tdctri ($RTRI,$MTRI,$NTRI,3,$WSMX);
}
#
# Now, examine the triangles; change all those that have a rendering
# style of 1 to instead have a rendering style that increases with
# the third coordinate of the triangle.  However, if the values of
# U, V, or W are in the ranges where we want a cyan stripe, we use
# rendering style NLYR+2.
#
for my $I ( 1 .. $NTRI ) {
   my $UPOS=( at( $RTRI, 0, $I-1 ) + at( $RTRI, 3, $I-1 ) + at( $RTRI, 6, $I-1 ) )/3.;
   my $VPOS=( at( $RTRI, 1, $I-1 ) + at( $RTRI, 4, $I-1 ) + at( $RTRI, 7, $I-1 ) )/3.;
   my $WPOS=( at( $RTRI, 2, $I-1 ) + at( $RTRI, 5, $I-1 ) + at( $RTRI, 8, $I-1 ) )/3.;
   if( at( $RTRI, 9, $I-1 ) == 1 ) {
     set( $RTRI, 9, $I-1,
          &NCAR::Test::max(1,&NCAR::Test::min($NLYR,1+int(($WPOS-$WMIN)/$WLYR)))
        );
   }
   if( ( ( $UPOS >= $USMN ) && ( $UPOS <= $USMX ) ) ||
       ( ( $VPOS >= $VSMN ) && ( $VPOS <= $VSMX ) ) ||
       ( ( $WPOS >= $WSMN ) && ( $WPOS <= $WSMX ) ) ) {
     set( $RTRI, 9, $I-1, $NLYR+2 );
   }
}
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
my $DU = $UMAX-$UMIN;
my $DV = $VMAX-$VMIN;
my $DW = $WMAX-$WMIN;
my $R=$RMUL*sqrt($DU*$DU+$DV*$DV+$DW*$DW);
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
my $OTEP;
if( $ISTE == 0 ) {
  $OTEP=0.                    #  (single view);
} else {
  $OTEP=-$R*&Tan($DTOR*$ASTE/2.)  #  (left-eye view);
}
#
# Initialize TDPACK.
#
L110:
&NCAR::tdinit ($UEYE,$VEYE,$WEYE,$UMID,$VMID,$WMID,$UMID,$VMID,$WMID+$R,$OTEP);
#
# If stereo views are being done, do the requested thing, either by
# redoing the SET call to put them side by side on the same frame,
# or by calling FRAME to put them on separate frames.
#
if( $OTEP != 0 ) {
  if( $ISTE < 0 ) {
    &NCAR::getset (my ( $XVPL,$XVPR,$YVPB,$YVPT,$XWDL,$XWDR,$YWDB,$YWDT,$LNLG ) );
    if( $OTEP < 0 ) {
    &NCAR::set  (1.-$WOSW,1.,.5-.5*$WOSW,.5+.5*$WOSW, $XWDL,$XWDR,$YWDB,$YWDT,$LNLG);
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
  print STDERR "\nTRIANGLE LIST OVERFLOW IN TDOTRI\n";
  exit();
}
#
# Draw labels for the axes.
#
&NCAR::tdlbls ($UMIN,$VMIN,$WMIN,$UMAX,$VMAX,$WMAX,$UNLB,$VNLB,$WNLB,$UILB,$VILB,$WILB,1);
#
# Draw the sides of the box that could be hidden.
#
&NCAR::tdgrds ($UMIN,$VMIN,$WMIN,$UMAX,$VMAX,$WMAX,.1*($UMAX-$UMIN),.1*($VMAX-$VMIN),.1*($WMAX-$WMIN),12,1);
#
# Draw the triangles in the triangle list.
#
&NCAR::tddtri ($RTRI,$MTRI,$NTRI,$ITWK);
#
# Draw the sides of the box that could not be hidden.
#
&NCAR::tdgrds ($UMIN,$VMIN,$WMIN,$UMAX,$VMAX,$WMAX, .1*($UMAX-$UMIN),.1*($VMAX-$VMIN),.1*($WMAX-$WMIN),12,0);
#
# If a left-eye view has just been done, loop back for a right-eye view.
#
if( $OTEP < 0 ) {
  $OTEP=-$OTEP;
  goto L110;
}
#
# Advance the frame.
#
&NCAR::frame();
#
# Close GKS.
#
&NCAR::clsgks();



rename 'gmeta', 'ncgm/tdex04.ncgm';
