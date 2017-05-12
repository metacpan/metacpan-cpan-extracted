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
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
#	$Id: stex02.f,v 1.6 1995/06/14 13:57:12 haley Exp $
#
# Example STEX02 demonstrates how both the field flow utilities -
# Vectors and Streamlines - map into the non-uniform coordinate
# systems supported by the NCAR Graphics SET call. Each of the
# five frames display a uniform 45 degree field using a Streamlines
# representation overlaying a Vectors representation. The first four
# frames cycle through all possible settings of the Linear-Log (LL)
# argument to the SET call. The fifth frame shows a user coordinate
# system where the unit X is twice the size of the unit Y.
#
# The example also illustrates use of the compatibility mode parameter
# to allow use of the older interfaces (VELVCT and STRMLN), while
# still accessing post-Version 3.2 capabilities of the field flow
# utilities. Note that use of the old entry-points is discouraged
# other than on a transitional basis. Therefore the comments show the
# code required to create an identical plot using the Version 3.2 
# interfaces.
#
my ( $M, $N ) = ( 25, 25 );
my $U = zeroes float, $N, $M;
my $V = zeroes float, $N, $M;
my $WRK = zeroes float, $M*$N*2;
#
# Specify the NDC coordinates for a plot title.
#
my ( $FX, $FY ) = ( 0.090909, 0.976540 );
#
# Specify VELVCT arguments.
#
my ( $FLO, $HI, $NSET, $LENGTH, $ISPV, $SPV ) = ( 0 ) x 6;
#
# Initialize the error parameter.
#
my $IERROR = 1;
#
# Specify velocity field component arrays U and V.
#
for my $I ( 1 .. $M ) {
  for my $J ( 1 .. $N ) {
    set( $U, $J-1, $I-1, 1 );
    set( $V, $J-1, $I-1, 1 );
  }
}
#
# Generate five frames:
# Frame 1: X-Axis linear, Y-Axis linear, equal units
# Frame 2: X-Axis linear, Y-Axis log
# Frame 3: X-Axis log, Y-Axis linear
# Frame 4: X-Axis log, Y-Axis log
# Frame 5: X-Axis linear, Y-Axis linear, 1 X unit = 2 Y units
#
for my $I ( 1 .. 5 ) {
#   
  my ( $XMX, $LL );
  if( $I == 5 ) {        
    $XMX=50.0;
    $LL=1;
  } else {
    $XMX=100.0;
    $LL=$I;
  }
#
# Set up the user coordinate system and the data coordinate
# boundaries.
#
  &NCAR::set(0.05,0.95,0.05,0.95,1.0,$XMX,1.0,100.0,$LL);
  &NCAR::vvsetr('XC1 -- Lower X Bound', 1.0);
  &NCAR::vvsetr('XCM -- Upper X Bound', $XMX);
  &NCAR::vvsetr('YC1 -- Lower X Bound', 1.0);
  &NCAR::vvsetr('YCN -- Upper Y Bound', 100.0);
  &NCAR::stsetr('XC1 -- Lower X Bound', 1.0);
  &NCAR::stsetr('XCM -- Upper X Bound', $XMX);
  &NCAR::stsetr('YC1 -- Lower X Bound', 1.0);
  &NCAR::stsetr('YCN -- Upper Y Bound', 100.0);
#
# Set the compatibility mode parameters: 
# (1) negative to allow use of Version 3.2 mapping routines 
# (the old mapping routines, FX and FY, do not support non-uniform 
# coordinates, and in addition, must be custom coded to support the
# data coordinate to user coordinate mapping); 
# (2) to absolute value less than 3 to cause the option input 
# arguments for VELVCT and STRMLN (FLO,HI,NSET,LENGTH,ISPV, and SPV) 
# to override the equivalent Version 3.2 parameters; 
# (3) to an even value, specifying that old common blocks be ignored.
#
# This setting causes the value of the NSET parameter to
# determine whether the utilities perform a SET call. If NSET = 1 
# the utilities do not perform the set call. 
#
# ====================================================================
  &NCAR::vvseti('CPM -- Compatibility Mode', -2) ;
  &NCAR::stseti('CPM -- Compatibility Mode', -2) ;
  my $NSET=1;
  &NCAR::gsplci(3);
  &NCAR::velvct ($U,$M,$V,$M,$M,$N,$FLO,$HI,$NSET,$LENGTH,$ISPV,float([0,0]));
  &NCAR::gsplci(7);
  &NCAR::strmln ($U,$V,$WRK,$M,$M,$N,$NSET,my $IER);
# ====================================================================
#
# To produce the same plot using Version 3.2 interfaces, comment out
# the code between this comment and the preceeding one, and uncomment
# the following code (Note that here CPM is left at its default value
# of 0 and the SET parameter is given the value of 0 to specify that
# the utilities should not perform a SET call):
#
# You could try setting the transformation type parameter, TRT, to 0 
# to see the effect it has on the plot frames.
#
#         CALL VVSETI('TRT - Transfomation Type', 0)
#         CALL STSETI('TRT - Transfomation Type', 0)
#
# ====================================================================
#$$$         IDM=0
#$$$         RDM=0
#$$$         CALL VVSETI('SET - Do-SET-Call Flag', 0)
#$$$         CALL STSETI('SET - Do-SET-Call Flag', 0)
#$$$         CALL GSPLCI(3)
#$$$         CALL VVINIT(U,M,V,M,RDM,IDM,M,N,RDM,IDM)
#$$$         CALL VVECTR(U,V,RDM,IDM,IDM,RDM)
#$$$         CALL GSPLCI(7)
#$$$         CALL STINIT(U,M,V,M,RDM,IDM,M,N,WRK,2*M*N)
#$$$         CALL STREAM(U,V,RDM,IDM,IDM,WRK)
# ====================================================================
#
# Save the current normalization transformation then set it to 0
#
  &NCAR::gqcntn(my $IERR,my $ICN);
  &NCAR::gselnt(0);
  my $X = &NCAR::cfux($FX);
  my $Y = &NCAR::cfuy($FY);
#
# Call PLCHLQ to write the plot title.
#
  &NCAR::plchlq ($X,$Y,'Streamlines Plotted Over a Uniform Vector Field',16.,0.,-1.);
#
# Restore the normalization transformation
#
  &NCAR::gselnt($ICN);
  &NCAR::frame();
#
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/stex02.ncgm';
