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
use NCAR::Test;
use strict;


my ( $IMAX, $JMAX, $KMAX, $MTRI ) = ( 41, 41, 41, 200000 );
#
# Declare local dimensioned variables to hold data defining a simple
# surface and an isosurface.
#
my $U = zeroes float, $IMAX;
my $V = zeroes float, $JMAX;
my $W = zeroes float, $KMAX;
my $S = zeroes float, $JMAX, $IMAX;
my $F = zeroes float, $IMAX, $JMAX, $KMAX;
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
my ( $UMIN,$VMIN,$WMIN,$UMAX,$VMAX,$WMAX ) = ( -1.,-1.,-1.,1.,1.,1. );
#
# Set the desired values of the dimensions of the data arrays.  Note
# that IDIM must not exceed IMAX, that JDIM must not exceed JMAX, and
# that KDIM must not exceed KMAX.
#
 my ( $IDIM,$JDIM,$KDIM ) = ( 31,31,31 );
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
my ( $SHDE,$SHDR ) = ( .1 , .8 );
#
# Set the desired values of the rendering-style indices for the
# isosurface and the simple surface, respectively.
#
my ( $IIRS,$ISRS ) = ( 2,3 );
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
# Define plot labels.
#
my @LABL = ( 'IMAP = 0',
             'IMAP = 1',
             'IMAP = 2',
             'IMAP = 3' );
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
&NCAR::tdclrs (1,$IBOW,$SHDE,$SHDR,11,42,4);
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
for my $I ( 1 .. $IDIM  ) {
  set( $U, $I-1, $UMIN+(($I-1)/($IDIM-1))*($UMAX-$UMIN) );
}
#
for my $J ( 1 .. $JDIM  ) {
  set( $V, $J-1, $VMIN+(($J-1)/($JDIM-1))*($VMAX-$VMIN) );
}
#
for my $K ( 1 .. $KDIM  ) {
  set( $W, $K-1, $WMIN+(($K-1)/($KDIM-1))*($WMAX-$WMIN) );
}
#
for my $I ( 1 .. $IDIM ) {
  my $U2 = at( $U, $I-1 ) * at( $U, $I-1 );
  for my $J ( 1 .. $JDIM  ) {
    my $V2 = at( $V, $J-1 ) * at( $V, $J-1 );
    set( $S, $J-1, $I-1, 2.*exp(-2.*($U2+$V2))-1. );
    for my $K ( 1 .. $KDIM ) {
      my $W2 = at( $W, $K-1 ) * at( $W, $K-1 );
      set( $F, $I-1, $J-1, $K-1, 1.25*$U2+1.25*$V2+5.*$W2 );
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
# 1-7 can then be used as final arguments in calls to TDITRI, TDSTRI,
# and TDMTRI.
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
# Find the midpoint of the data box (to be used as the point looked at).
#
my $UMID=.5*($UMIN+$UMAX);
my $VMID=.5*($VMIN+$VMAX);
my $WMID=.5*($WMIN+$WMAX);
#
# Determine the distance (R) from which the data box will be viewed and,
# given that, the eye position.
#
my $R=$RMUL*sqrt(
            ($UMAX-$UMIN)*($UMAX-$UMIN)
           +($VMAX-$VMIN)*($VMAX-$VMIN)
           +($WMAX-$WMIN)*($WMAX-$WMIN));
#
my $UEYE=$UMID+$R*cos($DTOR*$ANG1)*cos($DTOR*$ANG2);
my $VEYE=$VMID+$R*sin($DTOR*$ANG1)*cos($DTOR*$ANG2);
my $WEYE=$WMID+$R*sin($DTOR*$ANG2);
#
# Initialize the mapping parameter to do no mapping on the first frame.
#
my $IMAP=0;
#
# Initialize the count of triangles in the triangle list.
#
my $NTRI;
L108:
$NTRI=0;
#
# Add to the triangle list triangles representing a simple surface.
#
&NCAR::tdstri ($U,$IDIM,$V,$JDIM,$S,$IMAX,$RTRI,$MTRI,$NTRI,$ISRS);
#
if( $NTRI == $MTRI ) {
   print STDERR "\nTRIANGLE LIST OVERFLOW IN TDSTRI\n";
   exit( 0 );
}
#
# Add to the triangle list triangles representing an isosurface.
#
&NCAR::tditri ($U,$IDIM,$V,$JDIM,$W,$KDIM,$F,$IMAX,$JMAX,1.,$RTRI,$MTRI,$NTRI,$IIRS);
#
if( $NTRI == $MTRI ) {
   print STDERR "\nTRIANGLE LIST OVERFLOW IN TDITRI\n";
   exit( 0 );
}
#
# Apply a mapping to the XYZ coordinates of the vertices of the
# triangles in the triangle list.
#
&TDMXYZ ($IMAP,$RTRI,$MTRI,$NTRI);
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
  $OTEP = 0;                                  #  (single view)
} else {
  $OTEP = - $R * Tan( $DTOR * $ASTE / 2. );   #  (left-eye view)
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
  print STDERR "\nTRIANGLE LIST OVERFLOW IN TDOTRI\n";
  exit( 0 );
}
#
# Draw labels for the axes.
#
&NCAR::tdlbls ($UMIN,$VMIN,$WMIN,$UMAX,$VMAX,$WMAX,$UNLB,$VNLB,$WNLB,$UILB,$VILB,$WILB,1);
#
# Draw the sides of the box that could be hidden.
#
&NCAR::tdgrds ($UMIN,$VMIN,$WMIN,$UMAX,$VMAX,$WMAX,1*($UMAX-$UMIN),.1*($VMAX-$VMIN),.1*($WMAX-$WMIN),12,1);
#
# Draw the triangles in the triangle list.
#
&NCAR::tddtri ($RTRI,$MTRI,$NTRI,$ITWK);
#
# Draw the sides of the box that could not be hidden.
#
&NCAR::tdgrds ($UMIN,$VMIN,$WMIN,$UMAX,$VMAX,$WMAX,.1*($UMAX-$UMIN),.1*($VMAX-$VMIN),.1*($WMAX-$WMIN),12,0);
#
# Put a label below the box.
#
if( $ISTE == 0 ) {
&NCAR::plchhq(0.,-1.9,
    substr( 
            $LABL[$IMAP], 
            &IOFNBC($LABL[$IMAP])-1, 
            &IOLNBC($LABL[$IMAP]) - &IOFNBC($LABL[$IMAP]) + 1
          ),
    .02,0.,0.);
            
} else {
&NCAR::plchhq(0.,0.,
    substr( 
            $LABL[$IMAP], 
            &IOFNBC($LABL[$IMAP])-1, 
            &IOLNBC($LABL[$IMAP]) - &IOFNBC($LABL[$IMAP]) + 1
          ),
    .02,0.,0.);
}
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
# If the last image has not been done, bump the mapping selector and
# loop back for the next.
#
if( $IMAP < 3 ) {
  $IMAP=$IMAP+1;
  goto L108;
}
#
# Close GKS.
#
&NCAR::clsgks();
#
# Done.
#

sub TDMXYZ {
  my ($IMAP,$RTRI,$MTRI,$NTRI) = @_;
#
  my ( $PI, $PIO2, $PIO4 ) = (
    3.14159265358979323846,
    1.57079632679489661923,
    0.78539816339744830461,
  );
#
# This routine can be made to map the XYZ coordinates of the vertices
# of the triangles in a triangle list.  It is not to be viewed as a
# general-purpose routine, but only as an example, illustrating what
# can be done.
#
# Note that the contents of the array RTRI defines NTRI triangles; the
# Ith triangle is defined by the following vertices:
#
#   (RTRI(1,I),RTRI(2,I),RTRI(3,I))
#   (RTRI(4,I),RTRI(5,I),RTRI(6,I))
#   (RTRI(7,I),RTRI(8,I),RTRI(9,I))
#
# RTRI(10,I) is a "rendering style" for the triangle; it should not be
# modified.
#
# Using IMAP = 0 selects the identity mapping - the contents of RTRI
# are not changed.
#
# Using IMAP = 1 sort of turns the object being viewed "upside down".
# Actually, it creates a mirror image of the original; we swap points
# 1 and 2 of each triangle to keep the rendering consistent with that
# of the untransformed object.
#
  if( $IMAP == 1 ) {
#
    for my $ITRI ( 1 .. $NTRI ) {
       set( $RTRI, 3-1, $ITRI-1, -at( $RTRI, 3-1, $ITRI-1 ) );#Negate Z for vertex 1.
       set( $RTRI, 6-1, $ITRI-1, -at( $RTRI, 6-1, $ITRI-1 ) );#Negate Z for vertex 2.
       set( $RTRI, 9-1, $ITRI-1, -at( $RTRI, 9-1, $ITRI-1 ) );#Negate Z for vertex 3.
       my $XTMP = at( $RTRI, 1-1, $ITRI-1 );
       my $YTMP = at( $RTRI, 2-1, $ITRI-1 );
       my $ZTMP = at( $RTRI, 3-1, $ITRI-1 );
       set( $RTRI, 1-1, $ITRI-1, at( $RTRI, 4-1, $ITRI-1 ) );
       set( $RTRI, 2-1, $ITRI-1, at( $RTRI, 5-1, $ITRI-1 ) );
       set( $RTRI, 3-1, $ITRI-1, at( $RTRI, 6-1, $ITRI-1 ) );
       set( $RTRI, 4-1, $ITRI-1, $XTMP );
       set( $RTRI, 5-1, $ITRI-1, $YTMP );
       set( $RTRI, 6-1, $ITRI-1, $ZTMP );
    }
#
  }
#
# Using IMAP = 2 simply maps each each X, Y, and Z coordinate into
# the sine of pi/2 times the value of the coordinate, which carries
# the range [-1,1] back into [-1,1].
#
  if( $IMAP == 2 ) {
#
    for my $ITRI ( 1 .. $NTRI ) {
      for my $I ( 1 .. 9 ) {
        set( $RTRI, $I-1, $ITRI-1, sin( $PIO2 * at( $RTRI, $I-1, $ITRI-1 ) ) );
      }
    }
#
  }
#
# Using IMAP = 3 causes the X, Y, and Z coordinates to be identified
# with a pseudo-latitude (values from -1 to +1 are interpreted as being
# from 0 degrees to 90 degrees), pseudo-longitude (values from -1 to +1
# are interpreted as being from 0 degrees to 90 degrees), and radius
# (values from -1 to +1 are interpreted as being from .5 to 1),
# respectively.  The resulting X, Y, and Z coordinates are all between
# 0 and 1, so, in a separate step, we scale them to the range from -1
# to 1 in order to get a larger image.  As with IMAP = 1, there is a
# mirror-image effect and we have to swap points 1 and 2 in order to
# render the surfaces in the desired colors.
#
  if( $IMAP == 3 ) {
#
    for my $ITRI ( 1 .. $NTRI ) {
      for my $I ( 0, 3, 6 ) {
         my $RLAT=( at( $RTRI, $I+0, $ITRI-1 )+1.)*$PIO4;
         my $RLON=( at( $RTRI, $I+1, $ITRI-1 )+1.)*$PIO4;
         my $RADI=( at( $RTRI, $I+2, $ITRI-1 )+3.)/4.;
         set( $RTRI, $I+0, $ITRI-1, $RADI*cos($RLAT)*cos($RLON) );
         set( $RTRI, $I+1, $ITRI-1, $RADI*cos($RLAT)*sin($RLON) );
         set( $RTRI, $I+2, $ITRI-1, $RADI*sin($RLAT) );
         set( $RTRI, $I+0, $ITRI-1, 2.5*at( $RTRI, $I+0, $ITRI-1 )-1. );
         set( $RTRI, $I+1, $ITRI-1, 2.5*at( $RTRI, $I+1, $ITRI-1 )-1. );
         set( $RTRI, $I+2, $ITRI-1, 2.5*at( $RTRI, $I+2, $ITRI-1 )-1. );
      }
      my $XTMP= at( $RTRI, 1-1, $ITRI-1 );
      my $YTMP= at( $RTRI, 2-1, $ITRI-1 );
      my $ZTMP= at( $RTRI, 3-1, $ITRI-1 );
      set( $RTRI, 1-1, $ITRI-1, at( $RTRI, 4-1, $ITRI-1 ) );
      set( $RTRI, 2-1, $ITRI-1, at( $RTRI, 5-1, $ITRI-1 ) );
      set( $RTRI, 3-1, $ITRI-1, at( $RTRI, 6-1, $ITRI-1 ) );
      set( $RTRI, 4-1, $ITRI-1, $XTMP );
      set( $RTRI, 5-1, $ITRI-1, $YTMP );
      set( $RTRI, 6-1, $ITRI-1, $ZTMP );
    }
#
  }
#
# Done.
#
}

sub IOFNBC {
  my ( $CHRS ) = @_;
  for my $I ( 1 .. length( $CHRS ) ) {
    if( substr( $CHRS, $I-1, 1 ) ne ' ' ) {
      return $I;
    }
  }
  return 1;
}

sub IOLNBC {
  my ( $CHRS ) = @_;
  for( my $I = length( $CHRS ); $I >= 1; $I-- ) {
    if( substr( $CHRS, $I-1, 1 ) ne ' ' ) {
      return $I;
    }
  }
  return 1;
}

rename 'gmeta', 'ncgm/tdex05.ncgm';
