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
use strict;
  
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );


#
#
# This example illustrates use of the user-modifiable routine
# VVUMXY to create user-defined mappings of vector data.
# The first frame demonstrates a method of plotting data contained
#  in an irregularly spaced rectangular grid. 
# The second frame plots scattered (non-gridded) data.
# The third frame maps scattered data through an EZMAP projection.
#

my $MAXDIM = 100;
my $XCOORD = zeroes float, $MAXDIM;
my $YCOORD = zeroes float, $MAXDIM;
#
# Draw an irregularly gridded vector plot.
#
&IRREX();
#
# Draw a scattered vector plot.
#
&SCTREX();
#
# Draw a plot of scattered vectors mapped through an Ezmap projection.
#
&SCEZEX();
#
#
# =============================================================
#



sub IRREX {
#
#     
  my ( $M, $N ) = ( 10, 10 );
  my $U = zeroes float, $M, $N;
  my $V = zeroes float, $M, $N;
  my $PI = 3.14159;
  my $MAXDIM = 100;

#
# Local arrays to hold the coordinate data.
#
  my $XCLOC = float [ 0.0,7.5,20.0,40.0,45.0,65.0,70.0,77.0,90.0,95.0 ];
  my $YCLOC = float [ 12.5,22.5,30.0,35.0,52.0,58.0,70.0,75.0,85.0,90.0 ];
#
  my $XGRID = 100.0;
  my $YGRID = 100.0;
#
#
# Specify the NDC coordinates for a plot title.
#
  my ( $FX, $FY ) = ( 0.5, 0.975 );
#
# Set up a functionally defined vector field
#
  my $GXSIZE = $PI/$XGRID;
  my $GYSIZE = $PI/$YGRID;
  for my $I ( 1 .. $M ) {
    for my $J ( 1 .. $N ) {
      set( $U, $I-1, $J-1, cos( $GXSIZE * at( $XCLOC, $I-1 ) ) );
      set( $V, $I-1, $J-1, sin( $GYSIZE * at( $YCLOC, $J-1 ) ) );
    }
  }
#
# Copy coordinate values into the VVUSER common block arrays, in
# order to make the data accessible to VVUMXY.
#
  for my $I ( 1 .. $M ) {
    set( $XCOORD, $I-1, at( $XCLOC, $I-1 ) );
  }
#
  for my $I ( 1 .. $N ) {
    set( $YCOORD, $I-1, at( $YCLOC, $I-1 ) );
  }
#
# Set the user space (arguments 5,6,7, and 8 of the SET call) to contain 
# the extremes of the values assigned to the coordinate arrays; then
# tell Vectors not to do a SET call.
# 
  &NCAR::set(0.05,0.95,0.05,0.95,0.0,100.0,0.0,100.0,1);
  &NCAR::vvseti('SET - Do-SET-Call Flag', 0);
#
# Set the data coordinate boundaries equal to the grid coordinate
# boundaries (i.e. the range of the array indexes). This is actually
# the default condition for Vectors, but is included for emphasis here.
#
  &NCAR::vvsetr('XC1 -- Lower X Bound', 1.0);
  &NCAR::vvsetr('XCM -- Upper X Bound', $M);
  &NCAR::vvsetr('YC1 -- Lower Y Bound', 1.0);
  &NCAR::vvsetr('YCN -- Upper Y Bound', $N);
#
# Set the MAP parameter to a value indicating a user-defined mapping
# (anything other than 0, 1, or 2). The routine VVUMXY must be modified
# to recognize this value for MAP.
#
  &NCAR::vvseti('MAP - user-defined mapping', 3) ;
  my $IDM=0;
  my $RDM=0.0;
  &NCAR::vvinit($U,$M,$V,$M,float([]),$IDM,$M,$N,float([]),$IDM);
#
# For an irregular grid the default vector sizes may not be appropriate.
# The following (admittedly cumbersome) code adjusts the size relative 
# to the default size chosen by Vectors. It must follow VVINIT.
#
  my $VSZADJ = 0.75;
  &NCAR::vvgetr('DMX - NDC Maximum Vector Size', my $DMX);
  &NCAR::getset(my ( $VL,$VR,$VB,$VT,$UL,$UR,$UB,$UT,$LL ) );
  my $VRL = $VSZADJ * $DMX / ($VR - $VL);
  &NCAR::vvsetr('VRL - Vector Realized Length', $VRL);
#
  &NCAR::vvectr($U,$V,float([]),long([]),$IDM,float([]));
  &NCAR::perim(1,0,1,0);
#
# Save the current normalization transformation then set it to 0.
#
  &NCAR::gqcntn(my $IERR,my $ICN);
  &NCAR::gselnt(0);
  my $X = &NCAR::cfux($FX);
  my $Y = &NCAR::cfuy($FY);
#
# Call PLCHLQ to write the plot title.
#
  &NCAR::plchlq ($X,$Y,'Irregularly gridded vector data',16.,0.,0.);
#
# Restore the normalization transformation.
#
  &NCAR::gselnt($ICN);
  &NCAR::frame();
#
#
}
#
# ==================================================================
#
sub SCTREX {
#
# In this routine the U and V arrays are treated as single-dimensioned
# entities. The location of the vector with components U(I),V(I) is
# specified by XCLOC(I),YCLOC(I). The coordinate locations are copied
# to the common block VVUSER in order to make them accessible to the
# the user-defined mapping routine, VVUMXY.
#
# Since Vectors expects 2-D arrays for U and V, the input parameters
# M and N multiplied together should equal the total number of elements 
# in each of the 1-D data arrays.
#  
  my ( $M, $N ) = ( 10, 1 );
#
# User-defined common block containing X and Y locations of each 
# vector.
#
  my $MAXDIM = 100;
#
  my $XCLOC = float [ 40.0,7.5,20.0,35.0,45.0,65.0,75.0,80.0,90.0,95.0 ];
  my $YCLOC = float [ 50.0,80.0,20.0,60.0,15.0,80.0,20.0,45.0,60.0,50.0 ];
  my $U = float [ [ .3,.6,.8,.2,.9,.8,-.4,-.3,.1,.2 ] ];
  my $V = float [ [ -.2,.1,.7,.6,.3,-.4,-.6,-.8,-.9,-.5 ] ];
#
#
# Specify the NDC coordinates for a plot title.
#
  my ( $FX, $FY ) = ( 0.5, 0.975 );
#
# Copy coordinate values into the VVUSER common block arrays.
#
  for my $I ( 1 .. $M*$N ) {
    set( $XCOORD, $I-1, at( $XCLOC, $I-1 ) );
  }
#
  for my $I ( 1 .. $M*$N ) {
    set( $YCOORD, $I-1, at( $YCLOC, $I-1 ) );
  }
#
# Set the user space (arguments 5,6,7, and 8 of the SET call) to contain 
# the extremes of the values assigned to the coordinate arrays; then
# tell Vectors not to do a SET call.
# 
  &NCAR::set(0.075,0.925,0.1,0.95,0.0,100.0,0.0,100.0,1);
  &NCAR::vvseti('SET - Do-SET-Call Flag', 0);
#
# Set the data coordinate boundaries equal to the grid coordinate
# boundaries (i.e. the range of the array indexes). This is actually
# the default condition for Vectors, but is included for emphasis here.
#
&NCAR::vvsetr('XC1 -- Lower X Bound', 1.0);
&NCAR::vvsetr('XCM -- Upper X Bound', $M);
&NCAR::vvsetr('YC1 -- Lower Y Bound', 1.0);
&NCAR::vvsetr('YCN -- Upper Y Bound', $N);
#
# Set the MAP parameter to a value indicating a user-defined mapping
# (anything other than 0, 1, or 2). The routine VVUMXY must be modified
# to recognize this value for MAP.
#
  &NCAR::vvseti('MAP - user-defined mapping', 4) ;
  &NCAR::vvinit($U,$M,$V,$M,float([]),0,$M,$N,float([]),0);
#
# For an scattered grid the default vector sizes may not be appropriate.
# The following (admittedly cumbersome) code adjusts the size relative 
# to the default size chosen by Vectors. It must follow VVINIT.
#
  my $VSZADJ = 0.1;
  &NCAR::vvgetr('DMX - NDC Maximum Vector Size', my $DMX);
  &NCAR::getset( my ( $VL,$VR,$VB,$VT,$UL,$UR,$UB,$UT,$LL ) );
  my $VRL = $VSZADJ * $DMX / ($VR - $VL);
  &NCAR::vvsetr('VRL - Vector Realized Length', $VRL);
#
  &NCAR::vvectr($U,$V,float([]),long([]),sub {},float([]));
  &NCAR::perim(1,0,1,0);
#
#
# Save the current normalization transformation then set it to 0.
#
  &NCAR::gqcntn(my $IERR, my $ICN);
  &NCAR::gselnt(0);
  my $X = &NCAR::cfux($FX);
  my $Y = &NCAR::cfuy($FY);
#
# Call PLCHLQ to write the plot title.
#
  &NCAR::plchlq ($X,$Y,'Scattered vector data',16.,0.,0.);
#
# Restore the normalization transformation.
#
  &NCAR::gselnt($ICN);
  &NCAR::frame();
#
#
}
#
# =================================================================
#
sub SCEZEX {
#
# This routine maps geographically scattered vector data
# through an Ezmap projection. In order to make the effect of the 
# projection more obvious the vectors are given uniform direction 
# and magnitude.
# 
  my ( $M, $N ) = ( 20, 1 );
#
# User-defined common block containing X and Y locations of each 
# vector.
#
  my $MAXDIM = 100;
#
# All data lies within the region latitude 0.0,90.0 and 
# and longitude 0.0,100.0.
#
#
  my $XCLOC = float [ 40.0,7.5,20.0,35.0,40.0,65.0,75.0,80.0,90.0,95.0, 
                      50.0,80.0,20.0,60.0,15.0,80.0,20.0,45.0,60.0,50.0 ];
  my $YCLOC = float [ 50.0,80.0,20.0,60.0,15.0,80.0,20.0,45.0,60.0,50.0, 
                      40.0,7.5,20.0,35.0,45.0,65.0,75.0,13.0,24.0,32.0 ];
  my $U = float [ [ ( 1 ) x 20 ] ];
  my $V = float [ [ ( 1 ) x 20 ] ];
#
#
# Specify the NDC coordinates for a plot title.
#
  my ( $FX, $FY ) = ( 0.5, 0.975 );
#
# Copy coordinate values into the VVUSER common block arrays.
#
  for my $I ( 1 .. $M*$N ) {
    set( $XCOORD, $I-1, at( $XCLOC, $I-1 ) );
  }
#
  for my $I ( 1 .. $M*$N ) {
    set( $YCOORD, $I-1, at( $YCLOC, $I-1 ) );
  }
#
# Set up a Satellite view EZMAP projection. Draw the map grid only.
#
  &NCAR::mapset('MA',
                float( [ 0.0, 0.0 ] ),
                float( [ 0.0, 0.0 ] ),
                float( [ 0.0, 0.0 ] ),
                float( [ 0.0, 0.0 ] )
		);
  &NCAR::maproj('SV',45.0,50.0,0.0);
  &NCAR::mapint();
  &NCAR::mapgrd();
#
# Don't let Vectors do a SET call
#
  &NCAR::vvseti('SET - Do-SET-Call Flag', 0);
#
# Set the data coordinate boundaries equal to the grid coordinate
# boundaries (i.e. the range of the array indexes). This is actually
# the default condition for Vectors, but is included for emphasis here.
#
  &NCAR::vvsetr('XC1 -- Lower X Bound', 1.0);
  &NCAR::vvsetr('XCM -- Upper X Bound', $M);
  &NCAR::vvsetr('YC1 -- Lower Y Bound', 1.0);
  &NCAR::vvsetr('YCN -- Upper Y Bound', $N);
#
# Set the MAP parameter to a value indicating a user-defined mapping
# (anything other than 0, 1, or 2). The routine VVUMXY must be modified
# to recognize this value for MAP.
#
  &NCAR::vvseti('MAP - user-defined mapping', 5) ;
  &NCAR::vvsetr('LWD - vector linewidth', 2.0) ;
  &NCAR::vvinit($U,$M,$V,$M,float([]),0,$M,$N,float([]),0);
#
# Adjust vector sizes.
#
  my $VSZADJ = 0.1;
  &NCAR::vvgetr('DMX - NDC Maximum Vector Size', my $DMX);
  &NCAR::getset( my ( $VL,$VR,$VB,$VT,$UL,$UR,$UB,$UT,$LL ) );
  my $VRL = $VSZADJ * $DMX / ($VR - $VL);
  &NCAR::vvsetr('VRL - Vector Realized Length', $VRL);
#
  &NCAR::vvectr($U,$V,float([]),long([]),sub {},float([]));
  &NCAR::perim(1,0,1,0);
#
#
# Save the current normalization transformation then set it to 0.
#
  &NCAR::gqcntn( my $IERR, my $ICN);
  &NCAR::gselnt(0);
  my $X = &NCAR::cfux($FX);
  my $Y = &NCAR::cfuy($FY);
#
# Call PLCHLQ to write the plot title.
#
  &NCAR::plchlq ($X,$Y,'Scattered vector data mapped through an Ezmap projection',16.,0.,0.);
#
# Restore the normalization transformation.
#
  &NCAR::gselnt($ICN);
  &NCAR::frame();
#

#
}
#
# =================================================================
#
# Modified version of VVUMXY that implements mapping for the 
# following values of the Vectors 'MAP' internal parameter:
# 
# 3 - irregular rectangular grid mapping
# 4 - scattered data mapping
# 5 - scattered data mapped through an Ezmap projection.
#

sub NCAR::vvumxy {
  my ($X,$Y,$U,$V,$UVM,$XB,$YB,$XE,$YE,$IST) = @_;
#
# This is a user modifiable routine that allows custom projections of
# the vector space. X and Y give the vector position within the domain
# of the data space. By default, this space is coincident with the
# grid space (i.e. 1 through dimension lengths of the U and V arrays).
# The vector endpoints are output in fractional coordinates (NDC space).
# Note that this is different from the old MXF and MYF routines, which
# output in 'plotter coordinate' space. It also differs from the 
# Conpack routine CPMPXY, which returns values in user space. 
# 
# VVUMXY (Velocity Vector -- User Map X,Y) is called whenever 
# the internal parameter MAP is set to a value other than 0, 1, or 2.
#
# Based on the magnitude and direction of the vector the start and 
# ending points of the vector are returned in NDC space.
#
# Input parameters:
#
# X,Y   -- vector position in the user coordinate system
# U,V   -- vector components from the U,V arrays for this position
# UVM   -- magnitude of the U,V components (supplied for convenience
#          and efficiency - but note that many mappings do not need 
#          this value)
#
# Output parameters:
#
# XB,YB -- starting point of the vector in fractional coordinates
#          (NDC space)
# XE,YE -- ending point of the vector in fractional coordinates
#          (NDC space)
# IST   -- status results of the mapping: 0 indicates success -- any
#          non-zero value causes VVECTR to discard the vector at this
#          location
#
# The mapping common block: made available to user mapping routines.
# NOTE: all these variables should be considered read-only by VVUMXY.
#
#     COMMON /VVMAP/
#    +                IMAP       ,
#    +                XVPL       ,XVPR       ,YVPB       ,YVPT       ,
#    +                WXMN       ,WXMX       ,WYMN       ,WYMX       ,
#    +                XLOV       ,XHIV       ,YLOV       ,YHIV       ,
#    +                SXDC       ,SYDC       ,NXCT       ,NYCT       ,
#    +                RLEN       ,LNLG       ,INVX       ,INVY       ,
#    +                ITRT       ,IWCT       ,FW2W       ,FH2H       ,
#    +                DVMN       ,DVMX       ,RBIG       ,IBIG
#
  use NCAR::COMMON qw( %VVMAP );
#
# Description of VVMAP contents:
#
# IMAP                - value of the internal parameter 'MAP'
# XVPL,XVPR,YVPB,YVPT - the currently set viewport values. (GETSET
#                       arguments 1, 2, 3, and 4)
# WXMN,WXMX,WYMN,WYMX - the min and max boundaries of user coordinate
#                       space, (usually but not always equivalent to
#                       window coordinates). WXMN and WYMN are true
#                       minimum values even one or both axes is 
#                       inverted. (i.e. they are equivalent to GETSET
#                       arguments 5,6,7, and 8 sorted numerically)
# XLOV,XHIV,YLOV,YHIV - min and max boundaries of the data space, by
#                       default equivalent to the array grid space.
#                       XLOV and YLOV are not necessarily less than 
#                       XHIV and YHIV.
# SXDC,SYDC           - Scaling factors for converting vector component
#                       values into lengths in NDC space.
# NXCT,NYCT           - Length of each dimension of the U and V 
#                       component arrays.
# RLEN                - Length of the maximum vector in user 
#                       coordinates.
# LNLG                - The linear/log mode (GETSET argument 9)
# INVX,INVY           - User coordinates inversion flags: 
#                       0 - not inverted, 1 - inverted
# ITRT                - value of the internal parameter TRT
# IWCT                - not currently used
# FW2W,FH2H           - scale factors for converting from fraction of
#                       viewport width/height to NDC width/height 
# DVMN,DVMX           - min/max vector lengths in NDC
# RBIG,IBIG           - machine dependent maximum REAL/INTEGER values
#
# Math constants:
#
  my $PDTOR  = 0.017453292519943;
  my $PRTOD  = 57.2957795130823;
  my $P1XPI  = 3.14159265358979;
  my $P2XPI  = 6.28318530717959;
  my $P1D2PI = 1.57079632679489;
  my $P5D2PI = 7.85398163397448;
#
# --------------------------------------------------------------------
# User-defined common block:
#
  my $MAXDIM = 100;
#
# --------------------------------------------------------------------
# Local parameters (used for the Ezmap projection only):
#
# PRCFAC - Precision factor used to resolve float equality within
#            the precision of a 4 byte REAL
# PVFRAC - Initial fraction of the vector magnitude used to
#            determine the differential increment
# PFOVFL - Floating point overflow value
# IPMXCT - Number of times to allow the differential to increase
# PDUVML - Multiplier when the differential is increased
# PCSTST - Test value for closeness to 90 degree latitude
#
  my $PRCFAC=1E5;
  my $PVFRAC=0.001;
  my $PFOVFL=1E12;
  my $IPMXCT=40;
  my $PDUVML=2.0;
  my $IPCTST=$PRCFAC*90;
#
# ---------------------------------------------------------------------
#
  if( $VVMAP{IMAP} == 3 ) {
#
# Mapping for irregular rectangular gridded vector data.
# 
# Since the array grid and input data space are coincident in this
# case, X and Y converted to integers serve as the index into the 
# coordinate arrays that define the vector location in the user
# coordinate system. 
# This code includes more tests that may be necessary in
# production environments: it does so partly to illustrate how to use
# some of the contents of the VVMAP common block.
#
    my $I = int($X);
    my $J = int($Y);
#
# NXCT and NYCT contain the number of elements along each coordinate
# axis. Therefore the following test ensures that I and J are within
# the domain of the array dimensions.
#
    if( ( $I < 1 ) || ( $I > $VVMAP{NXCT} ) 
     || ( $J < 1 ) || ( $J > $VVMAP{NYCT} ) ) {
      $IST = -1;
      goto RETURN;
    }
    
    my $XC = at( $XCOORD, $I-1 );
    my $YC = at( $YCOORD, $J-1 );
#
# WXMN, WXMX, WYMN, and WYMX contain the minimum and maximum values of
# the user coordinate space. The following test ensures that the 
# coordinate values in the array are within the current boundaries
# of the user space.
#
    if( ( $XC < $VVMAP{WXMN} ) || ( $XC > $VVMAP{WXMX} ) 
     || ( $YC < $VVMAP{WYMN} ) || ( $YC > $VVMAP{WYMX} ) ) {
      $IST = -1;
      goto RETURN;
    }
    $XB=&NCAR::cufx($XC);
    $YB=&NCAR::cufy($YC);
    $XE=$XB+$U*$VVMAP{SXDC};
    $YE=$YB+$V*$VVMAP{SYDC};
#
# ---------------------------------------------------------------------
#
  } elsif( $VVMAP{IMAP} == 4 ) {
#
# Mapping for scattered vector data.
# 
    my $I = int($X);
    my $J = int($Y);
#
    if( ( $I < 1 ) || ( $I > $VVMAP{NXCT} ) 
     || ( $J < 1 ) || ( $J > $VVMAP{NYCT} ) ) {
      $IST = -1;
      goto RETURN;
    }
#
# Since XCOORD and YCOORD are actually single dimensional arrays,
# convert the 2-d indexes supplied to VVUMXY into their 1-d equivalent 
# to index into the coordinate arrays.
#
    my $XC = at( $XCOORD, $VVMAP{NXCT}*($J-1)+$I-1 );
    my $YC = at( $YCOORD, $VVMAP{NXCT}*($J-1)+$I-1 );
#
    if( ( $XC < $VVMAP{WXMN} ) || ( $XC > $VVMAP{WXMX} ) 
     || ( $YC < $VVMAP{WYMN} ) || ( $YC > $VVMAP{WYMX} ) ) {
      $IST = -1;
      goto RETURN;
    }
    $XB=&NCAR::cufx($XC);
    $YB=&NCAR::cufy($YC);
    $XE=$XB+$U*$VVMAP{SXDC};
    $YE=$YB+$V*$VVMAP{SYDC};
#
# ---------------------------------------------------------------------
#
  } elsif( $VVMAP{IMAP} == 5 ) {
#
# Mapping for scattered vector data projected through Ezmap. XCOORD and
# YCOORD contain the Longitude and Latitude respectively of each vector
# datum. 
#  
# 
    my $I = int($X);
    my $J = int($Y);
#
    if( ( $I < 1 ) || ( $I > $VVMAP{NXCT} ) 
     || ( $J < 1 ) || ( $J > $VVMAP{NYCT} ) ) {
      $IST = -1;
      goto RETURN;
    }
#
# Since XCOORD and YCOORD are actually single dimensional arrays,
# convert the 2-d indexes supplied to VVUMXY into their 1-d equivalent 
# to index into the coordinate arrays.
#
    my $XC = at( $XCOORD, $VVMAP{NXCT}*($J-1)+$I-1 );
    my $YC = at( $YCOORD, $VVMAP{NXCT}*($J-1)+$I-1 );
#
# The following code is adapted from the Ezmap projection code in 
# VVMPXY. An iterative technique is used that handles most vectors 
# arbitrarily close to the projection limb.
# XC is longitude, YC is latitude.
#
# Test for 90 degree latitude.
#
    if( int( abs( $YC ) * $PRCFAC + 0.5 ) == $IPCTST ) {
      $IST=-1;
      goto RETURN;
    }
#
# Project the starting value: bail out if outside the window
#
    &NCAR::maptra ($YC,$XC,$XB,$YB);
    if( ( $XB < $VVMAP{WXMN} ) || ( $XB > $VVMAP{WXMX} ) 
     || ( $YB < $VVMAP{WYMN} ) || ( $YB > $VVMAP{WYMX} ) ) {
      $IST=-5;
      goto RETURN;
    }
#
# Check the vector magnitude
#
    if( int( $UVM*$PRCFAC+0.5 ) == 0 ) {
      $IST=-2;
      goto RETURN;
    }
#
# The incremental distance is proportional to a small fraction
# of the vector magnitude
#
    my $DUV=$PVFRAC/$UVM;
    my $CLT=cos($YC*$PDTOR);
#
# Project the incremental distance. If the positive difference doesn't
# work, try the negative difference. If the difference results in a
# zero length vector, try a number of progressively larger increments.
#
    my $ICT=0;
    my $SGN=1.0;
L20:
#
    &NCAR::maptra($YC+$SGN*$V*$DUV,$XC+$SGN*$U*$DUV/$CLT,my ( $XT,$YT ) );
#
    my $DV1=sqrt(($XT-$XB)*($XT-$XB)+($YT-$YB)*($YT-$YB));
    if( $DV1 > $VVMAP{RLEN} ) {
      if( $SGN == -1 ) {
        $IST=-4;
        goto RETURN;
      } else {
        $SGN=-1.0;
        goto L20;
      }
    }
#
    if( int( $DV1*$PRCFAC ) == 0 ) {
      if( $ICT < $IPMXCT ) {
        $ICT = $ICT + 1;
        $DUV=$DUV*$PDUVML;
        goto L20;
      } else {
        $IST=-3;
        goto RETURN;
      }
    }
#
    if( ( abs( $XT ) >= $PFOVFL ) || ( abs( $YT ) >= $PFOVFL ) ) {
      $IST=-6;
      goto RETURN;
    }
#
    my $T;
    $T=$SGN*(($XT-$XB)/$DV1)*$UVM;
    $XB=&NCAR::cufx($XB);
    $XE=$XB+$T*$VVMAP{SXDC};
    $T=$SGN*(($YT-$YB)/$DV1)*$UVM;
    $YB=&NCAR::cufy($YB);
    $YE=$YB+$T*$VVMAP{SYDC};
#
# ---------------------------------------------------------------------
#
  } else {
#
# Default mapping:
#
# WXMN, WXMX, WYMN, and WYMX contain the minimum and maximum values of
# the user coordinate space. Somewhat inaccurately, the mmenomic 'W'
# implies window coordinate space, which is usually (but not always)
# the same as user coordinate space. But note that even when 
# the coordinates are reversed, you are guaranteed that WXMN .LT. WXMX
# and WYMN .LT. WYMX. This eliminates the need to invoke MIN and MAX.
#
    if( ( $X < $VVMAP{WXMN} ) || ( $X > $VVMAP{WXMX} ) 
     || ( $Y < $VVMAP{WYMN} ) || ( $Y > $VVMAP{WYMX} ) ) {
      $IST = -1;
      goto RETURN;
    }
    $XB=&NCAR::cufx($X);
    $YB=&NCAR::cufy($Y);
    $XE=$XB+$U*$VVMAP{SXDC};
    $YE=$YB+$V*$VVMAP{SYDC};
  }
#
# Done.
#
  RETURN:
  ( $_[5], $_[6], $_[7], $_[8], $_[9] )
  = ( $XB, $YB, $XE, $YE, $IST );
  return;
}


&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/vvex03.ncgm';
