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
   
#
#	$Id: tareas.f,v 1.5 1995/06/14 14:04:40 haley Exp $
#
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# OPEN GKS, OPEN WORKSTATION OF TYPE 1, ACTIVATE WORKSTATION
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# PURPOSE                To provide a simple demonstration of the use
#                        of AREAS.
#
# USAGE                  CALL TAREAS (IERROR)
#
# ARGUMENTS
#
# ON OUTPUT              IERROR
#
#                          an error parameter
#                          = 0, if the test is successful,
#                          = 1, otherwise
#
# I/O                    If the test is successful, the message
#
#                          AREAS TEST EXECUTED--SEE PLOTS TO CERTIFY
#
#                        is written on unit 6.
#
# PRECISION              Single.
#
# REQUIRED LIBRARY       AREAS, SPPS
# FILES
#
# REQUIRED GKS LEVEL     0A
#
# LANGUAGE               FORTRAN
#
# HISTORY                Written in JUNE, 1987.
#
# ALGORITHM              TAREAS constructs and colors a very simple
#                        picture illustrating the use of all of the
#                        routines in the package.
#
# PORTABILITY            FORTRAN 77
#
# Define an array in which to construct the area map.
#
my $IAM = zeroes long, 5000;
#
# Define the arrays needed for edge-coordinate data.
#
my $XCA = zeroes float, 73;
my $YCA = zeroes float, 73;
#
# Dimension the arrays needed by ARSCAM and ARDRLN for X/Y coordinates.
#
my $XCS = zeroes float, 150;
my $YCS = zeroes float, 150;
#
# Dimension the arrays needed by ARSCAM and ARDRLN for area and group
# identifiers.
#
my $IAI = zeroes long, 2;
my $IAG = zeroes long, 2;
#
# Define an array for GKS aspect source flags.
#
 my $IF = zeroes long, 13;
#
# Declare the routine which will color the areas.
#
#       EXTERNAL COLRAM
#
# Declare the routine which will draw lines over the circle.
#
#       EXTERNAL COLRLN
#
my @RGB = (
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
     [ 1.00 , 1.00 , 1.00 ],
);
my $IOC = long [ 6,2,5,12,10,11,1,3,4,8,9,7,13,14,15 ];
#
# Declare the constant for converting from degrees to radians.
#
my $DTR = .017453292519943;
#
# Set the aspect source flags for FILL AREA INTERIOR STYLE and for
# FILL AREA STYLE INDEX to "individual".
#
&NCAR::gqasf (my $IE,$IF);
set( $IF, 10, 1 );
set( $IF, 11, 1 );
&NCAR::gsasf ($IF);
#
# Force solid fill.
#
&NCAR::gsfais (1);
#
# Define 15 different color indices.
#
&NCAR::gscr($IWKID,0,0.,0.,0.);
for my $J ( 1 .. 15 ) {
  my $I = at( $IOC, $J-1 );
  &NCAR::gscr($IWKID,$J,@{ $RGB[$I-1] });
}
#
# Initialize the area map.
#
&NCAR::arinam ($IAM,5000);
#
# Add edges to the area map.
#
&NCAR::set (.01,.99,.01,.99,-1.,1.,-1.,1.,1);
#
# First, define a circle, using group 1 edges.  After this step, the
# area inside the circle has area identifier zero and the area outside
# has area identifier -1.
#
for my $ING ( 1 .. 73 ) {
  my $ANG=$DTR*(5*($ING-1));
  set( $XCA, $ING-1, cos($ANG) );
  set( $YCA, $ING-1, sin($ANG) );
}
&NCAR::aredam ($IAM,$XCA,$YCA,73,1,0,-1);
#
# Add lines splitting the circle into wedges.  The area identifiers
# for the wedges are added to the area map with this step.
#
set( $XCA, 0, 0 );
set( $YCA, 0, 0 );
for my $ING ( 1 .. 15 ) {
  my $ANG=$DTR*(24*($ING-1));
  set( $XCA, 1, cos( $ANG ) );
  set( $YCA, 1, sin( $ANG ) );
  &NCAR::aredam ($IAM,$XCA,$YCA,2,1,$ING,( ($ING+13) % 15)+1);
}
#
# Now, put in another, smaller, off-center circle, using a group 2
# edge.  The interior of the circle has area identifier 1 and the
# exterior of the circle has group identifier 2.
#
for my $ING ( 1 .. 73 ) {
  my $ANG=$DTR*(5*($ING-1));
  set( $XCA, $ING-1, .25+.5*cos($ANG) );
  set( $YCA, $ING-1, .25+.5*sin($ANG) );
}
&NCAR::aredam ($IAM,$XCA,$YCA,73,2,1,2);
#
# Pre-process the area map.
#
&NCAR::arpram ($IAM,0,0,0);
#
# Compute and print the amount of space used in the area map.
#
my $ISU=5000-(at( $IAM, 5 )-at( $IAM, 4 )-1);
print STDERR "\nSPACE USED IN AREA MAP IS $ISU\n";
#
# Color the areas defined.
#
&NCAR::arscam ($IAM,$XCS,$YCS,150,$IAI,$IAG,2,\&COLRAM);
#
# In contrasting colors, draw three stars on the plot.
#
for my $I ( 1 .. 3 ) {
  my ( $XCN, $YCN );
  if( $I == 1 ) {
    $XCN=-.5;
    $YCN=+.5;
  } elsif( $I == 2 ) {
    $XCN=-.5;
    $YCN=-.5;
  } elsif( $I == 3 ) {
    $XCN=+.5;
    $YCN=-.5;
  }
  set( $XCA, 1-1, $XCN+.25*cos( 162.*$DTR) );
  set( $YCA, 1-1, $YCN+.25*sin( 162.*$DTR) );
  set( $XCA, 2-1, $XCN+.25*cos(  18.*$DTR) );
  set( $YCA, 2-1, $YCN+.25*sin(  18.*$DTR) );
  set( $XCA, 3-1, $XCN+.25*cos(-126.*$DTR) );
  set( $YCA, 3-1, $YCN+.25*sin(-126.*$DTR) );
  set( $XCA, 4-1, $XCN+.25*cos(  90.*$DTR) );
  set( $YCA, 4-1, $YCN+.25*sin(  90.*$DTR) );
  set( $XCA, 5-1, $XCN+.25*cos( -54.*$DTR) );
  set( $YCA, 5-1, $YCN+.25*sin( -54.*$DTR) );
  set( $XCA, 6-1, $XCN+.25*cos( 162.*$DTR) );
  set( $YCA, 6-1, $YCN+.25*sin( 162.*$DTR) );
  &NCAR::ardrln ($IAM,$XCA,$YCA,6,$XCS,$YCS,150,$IAI,$IAG,2,\&COLRLN);
}
#
# Draw a spiral of points in the blanked-out circle, using the colors
# from edge group 1.
#
my $ICF=1;
for my $ING ( 1 .. 1500 ) {
  my $RAD=($ING)/1000.;
  my $ANG=$DTR*($ING-1);
  my $XCD=.25+.5*$RAD*cos($ANG);
  my $YCD=.25+.5*$RAD*sin($ANG);
  &NCAR::argtai ($IAM,$XCD,$YCD,$IAI,$IAG,2,my $NAI,$ICF);
  my $ITM=1;
  for my $I ( 1 .. $NAI ) {
    if( at( $IAI, $I-1 ) < 0 ) { $ITM = 0; }
  }
  if( $ITM != 0 ) {
    my $IT1=0;
    my $IT2=0;
    for my $I ( 1 .. $NAI ) {
      if( at( $IAG, $I-1 ) == 1 ) { $IT1 = at( $IAI, $I-1 ); }
      if( at( $IAG, $I-1 ) == 2 ) { $IT2 = at( $IAI, $I-1 ); }
    }
    if( ( $IT1 > 0 ) && ( $IT2 == 1 ) ) {
#
# Flush PLOTIT's buffers and set polyline color index.
#
      &NCAR::plotit(0,0,0);
      &NCAR::gsplci($IT1);
#
      &NCAR::point ($XCD,$YCD);
    }
  }
  $ICF=0;
}
#
# Advance the frame.
#
&NCAR::frame();
#
# Done.
#
print STDERR "\n  AREAS TEST EXECUTED--SEE PLOTS TO CERTIFY\n";

sub COLRAM {
  my ($XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
  my $ITM=1;
  for my $I ( 1 .. $NAI ) {
    if( at( $IAI, $I-1 ) < 0 ) { $ITM = 0; }
  }
  if( $ITM != 0 ) {
    my $IT1=0;
    my $IT2=0;
    for my $I ( 1 .. $NAI ) {
      if( at( $IAG, $I-1 ) == 1 ) { $IT1 = at( $IAI, $I-1 ); }
      if( at( $IAG, $I-1 ) == 2 ) { $IT2 = at( $IAI, $I-1 ); }
    }
    if( ( $IT1 > 0 ) && ( $IT2 != 1 ) ) { 
#
# Set fill area color index.
#
      &NCAR::gsfaci($IT1);
#
      &NCAR::gfa ($NCS-1,$XCS,$YCS);
    }
  }
}

sub COLRLN {
  my ($XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
  my $ITM=1;
  for my $I ( 1 .. $NAI ) {
    if( at( $IAI, $I-1 ) < 0 ) { $ITM = 0; }
  }
  if( $ITM != 0 ) {
    my $IT1=0;
    my $IT2=0;
    for my $I ( 1 .. $NAI ) {
      if( at( $IAG, $I-1 ) == 1 ) { $IT1 = at( $IAI, $I-1 ); }
      if( at( $IAG, $I-1 ) == 2 ) { $IT2 = at( $IAI, $I-1 ); }
    }
    if( ( $IT1 > 0 ) && ( $IT2 != 1 ) ) {
#
# Flush PLOTIT's buffers and set polyline color index.
#
       &NCAR::plotit(0,0,0);
       &NCAR::gsplci(( ($IT1+3) % 15)+1);
#
       &NCAR::gpl ($NCS,$XCS,$YCS);
     }
  }
}
#
# DEACTIVATE AND CLOSE WORKSTATION, CLOSE GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
 
   
rename 'gmeta', 'ncgm/tareas.ncgm';
