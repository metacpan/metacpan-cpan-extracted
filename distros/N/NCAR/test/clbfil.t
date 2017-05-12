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
#  Define error file, Fortran unit number, and workstation type,
#  and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );

my @LAB1 = ( 'Four','Different','Fill','Styles' );
my $IFILL1 = long [ 1,2,3,4 ];
#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Draw a horizontal bar
#
&NCAR::lblbar(0,.05,.95,.05,.95,4,1.,.3,$IFILL1,2,\@LAB1,4,1);
#
# Advance frame
#
&NCAR::frame();
#
#     DEACTIVATE AND CLOSE WORKSTATION, CLOSE GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();

sub NCAR::lbfill {
  my ($IFTP,$XRA,$YRA,$NRA,$INDX) = @_;
#
# Declare required dimensioned arrays.
#
  my $DST = zeroes float, 500;
  my $IND = zeroes long, 500;
#
# Define three different dot patterns.
#
  my $ID1 = long [
     [ 1,1,0,0,0,0,1,1 ],
     [ 1,1,0,1,1,0,1,1 ],
     [ 0,0,0,1,1,0,0,0 ],
     [ 0,1,1,1,1,1,1,0 ],
     [ 0,1,1,1,1,1,1,0 ],
     [ 0,0,0,1,1,0,0,0 ],
     [ 1,1,0,1,1,0,1,1 ],
     [ 1,1,0,0,0,0,1,1 ],
  ];
  my $ID2 = long [
     [ 0,0,0,0,0,0,0,0 ],
     [ 0,1,1,1,1,1,1,0 ],
     [ 0,1,1,1,1,1,1,0 ],
     [ 0,1,1,0,0,1,1,0 ],
     [ 0,1,1,0,0,1,1,0 ],
     [ 0,1,1,1,1,1,1,0 ],
     [ 0,1,1,1,1,1,1,0 ],
     [ 0,0,0,0,0,0,0,0 ],
  ];
  my $ID3 = long [
     [ 0,0,0,0,0,0,0,0 ],
     [ 0,1,1,0,0,1,1,1 ],
     [ 0,1,1,0,0,1,1,0 ],
     [ 0,1,1,0,1,1,0,0 ],
     [ 0,1,1,1,1,0,0,0 ],
     [ 0,1,1,0,1,1,0,0 ],
     [ 0,1,1,0,0,1,1,0 ],
     [ 0,1,1,0,0,1,1,1 ],
  ];
#
# Double the size of the GKS dot.
#
  &NCAR::gsmksc (2.);
#
# Fill the first box with a combination of lines and dots.
#
  if( $INDX == 1 ) {
    &NCAR::sfsetr ('SP - SPACING OF FILL LINES',.012);
    &NCAR::sfseti ('DO - DOT-FILL FLAG',0);
    &NCAR::sfwrld ($XRA,$YRA,$NRA,$DST,500,$IND,500);
    &NCAR::sfsetr ('SP - SPACING OF FILL LINES',.006);
    &NCAR::sfseti ('DO - DOT-FILL FLAG',1);
    &NCAR::sfnorm ($XRA,$YRA,$NRA,$DST,500,$IND,500);
  }
#
# Fill the second box with a specified dot pattern.
#
  if( $INDX == 2 ) {
    &NCAR::sfsetr ('SP - SPACING OF FILL LINES',.004);
    &NCAR::sfsetp ($ID1);
    &NCAR::sfwrld ($XRA,$YRA,$NRA,$DST,500,$IND,500);
  }
#
# Fill the third box with a different dot pattern, tilted at an
# angle.
#
  if( $INDX == 3 ) {
    &NCAR::sfseti ('AN - ANGLE OF FILL LINES',45);
    &NCAR::sfsetp ($ID2);
    &NCAR::sfwrld ($XRA,$YRA,$NRA,$DST,500,$IND,500);
  }
#
# Fill the last box with K's, both large and small.
#
  if( $INDX == 4 ) {
    &NCAR::gschh  (.008);
    &NCAR::sfsetr ('SP - SPACING OF FILL LINES',.012);
    &NCAR::sfsetc ('CH - CHARACTER SPECIFIER','K');
    &NCAR::sfsetp ($ID3);
    &NCAR::sfwrld ($XRA,$YRA,$NRA,$DST,500,$IND,500);
  }
#
# Done.
#
}

rename 'gmeta', 'ncgm/clbfil.ncgm';
