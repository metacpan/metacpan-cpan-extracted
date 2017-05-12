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
# This example produces no graphical output.  Instead, it produces
# print output demonstrating the use of some of the EZMAPB routines
# allowing one to retrieve information from the a map database.
#
##
# Read name information from the EZMAP database.
#
&NCAR::mplnri ('Earth..1');
#
# Do a simple check of some information-returning routines.  First, find
# the area in the database with a particular short name.
#
print STDERR "

Test routines that return area information:

  Search map database for Madeline Island.
";

#
my $IAID;
for my $I ( 1 .. 10000 ) {
  if( &NCAR::mpiaty( $I ) != 0 ) {
    my $CTMP=&NCAR::mpname($I);
    if( substr( $CTMP, 0, 15 ) eq 'Madeline Island' ) {
      $IAID=$I;
      printf( STDERR "

  Madeline Island has area identifier IAID = %4d\n", $IAID );
      goto L102;
    }
  } else {
      print STDERR " 

  Madeline Island not found in database.\n";
  
      goto L103;
  }
}
#
# Search failure.
#

print STDERR "


  Search failure - too many names in database.";
  
  goto L103;
#
# Write out simple information for the area.
#
L102:
printf( STDERR  "Its area type is &NCAR::mpiaty($IAID) =          %5d\n", &NCAR::mpiaty($IAID) );
printf( STDERR  "Its suggested color is &NCAR::mpisci($IAID) =    %5d\n", &NCAR::mpisci($IAID) );
printf( STDERR  "Its parent identifier is &NCAR::mpipar($IAID) =  %5d\n", &NCAR::mpipar($IAID) );
my $CTMP=&NCAR::mpname($IAID);
printf( STDERR  "Its short name is &NCAR::mpname($IAID) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP) ) );
#
print STDERR "
  Short name of smallest containing area at various display levels:
";
#
$CTMP=&NCAR::mpname(&NCAR::mpiosa($IAID,5));
printf( STDERR  "    &NCAR::mpname(&NCAR::mpiosa($IAID,5)) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
$CTMP=&NCAR::mpname(&NCAR::mpiosa($IAID,4));
printf( STDERR  "    &NCAR::mpname(&NCAR::mpiosa($IAID,4)) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
$CTMP=&NCAR::mpname(&NCAR::mpiosa($IAID,3));
printf( STDERR  "    &NCAR::mpname(&NCAR::mpiosa($IAID,3)) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
$CTMP=&NCAR::mpname(&NCAR::mpiosa($IAID,2));
printf( STDERR  "    &NCAR::mpname(&NCAR::mpiosa($IAID,2)) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
$CTMP=&NCAR::mpname(&NCAR::mpiosa($IAID,1));
printf( STDERR  "    &NCAR::mpname(&NCAR::mpiosa($IAID,1)) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
#
print STDERR "
  Short name of largest containing area at various  display levels:
";
#
$CTMP=&NCAR::mpname(&NCAR::mpiola($IAID,5));
printf( STDERR  "    &NCAR::mpname(&NCAR::mpiola($IAID,5)) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
$CTMP=&NCAR::mpname(&NCAR::mpiola($IAID,4));
printf( STDERR  "    &NCAR::mpname(&NCAR::mpiola($IAID,4)) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
$CTMP=&NCAR::mpname(&NCAR::mpiola($IAID,3));
printf( STDERR  "    &NCAR::mpname(&NCAR::mpiola($IAID,3)) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
$CTMP=&NCAR::mpname(&NCAR::mpiola($IAID,2));
printf( STDERR  "    &NCAR::mpname(&NCAR::mpiola($IAID,2)) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
$CTMP=&NCAR::mpname(&NCAR::mpiola($IAID,1));
printf( STDERR  "    &NCAR::mpname(&NCAR::mpiola($IAID,1)) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
#
print STDERR "
  Suggested color at various display levels:
";
#
printf( STDERR  "    &NCAR::mpisci(&NCAR::mpiosa($IAID,5)) = %1d\n", &NCAR::mpisci(&NCAR::mpiosa($IAID,5)) );
printf( STDERR  "    &NCAR::mpisci(&NCAR::mpiosa($IAID,4)) = %1d\n", &NCAR::mpisci(&NCAR::mpiosa($IAID,4)) );
printf( STDERR  "    &NCAR::mpisci(&NCAR::mpiosa($IAID,3)) = %1d\n", &NCAR::mpisci(&NCAR::mpiosa($IAID,3)) );
printf( STDERR  "    &NCAR::mpisci(&NCAR::mpiosa($IAID,2)) = %1d\n", &NCAR::mpisci(&NCAR::mpiosa($IAID,2)) );
printf( STDERR  "    &NCAR::mpisci(&NCAR::mpiosa($IAID,1)) = %1d\n", &NCAR::mpisci(&NCAR::mpiosa($IAID,1)) );
#
print STDERR "
  Full name at various display levels:
";
#
$CTMP=&NCAR::mpfnme(&NCAR::mpiosa($IAID,5),5);
printf( STDERR  "    &NCAR::mpfnme(&NCAR::mpiosa($IAID,5),5) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
$CTMP=&NCAR::mpfnme(&NCAR::mpiosa($IAID,4),4);
printf( STDERR  "    &NCAR::mpfnme(&NCAR::mpiosa($IAID,4),4) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
$CTMP=&NCAR::mpfnme(&NCAR::mpiosa($IAID,3),3);
printf( STDERR  "    &NCAR::mpfnme(&NCAR::mpiosa($IAID,3),3) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
$CTMP=&NCAR::mpfnme(&NCAR::mpiosa($IAID,2),2);
printf( STDERR  "    &NCAR::mpfnme(&NCAR::mpiosa($IAID,2),2) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
$CTMP=&NCAR::mpfnme(&NCAR::mpiosa($IAID,1),1);
printf( STDERR  "    &NCAR::mpfnme(&NCAR::mpiosa($IAID,1),1) = %s\n", substr( $CTMP, 0, &NCAR::mpilnb($CTMP)) );
#
print STDERR "
  Full name from a specified level down:
";
#
$CTMP=&NCAR::mpfnme($IAID,5);
my $LCTM=&NCAR::mpilnb($CTMP);
printf( STDERR  "    &NCAR::mpfnme($IAID,5) = %s\n", substr( $CTMP, 0, &NCAR::Test::min( 58,$LCTM)) );
if ($LCTM > 58) {
printf( STDERR  "                           %s\n", substr( $CTMP, 58, &NCAR::Test::min(116,$LCTM)-57 ) );
}
$CTMP=&NCAR::mpfnme($IAID,4);
$LCTM=&NCAR::mpilnb($CTMP);
printf( STDERR  "    &NCAR::mpfnme($IAID,4) = %s\n", substr( $CTMP, 0, &NCAR::Test::min( 58,$LCTM)) );
if ($LCTM > 58) {
printf( STDERR  "                           %s\n", substr( $CTMP, 58, &NCAR::Test::min(116,$LCTM)-57 ) );
}
$CTMP=&NCAR::mpfnme($IAID,3);
$LCTM=&NCAR::mpilnb($CTMP);
printf( STDERR  "    &NCAR::mpfnme($IAID,3) = %s\n", substr( $CTMP, 0, &NCAR::Test::min( 58,$LCTM)) );
if ($LCTM > 58) {
printf( STDERR  "                           %s\n", substr( $CTMP, 58, &NCAR::Test::min(116,$LCTM)-57 ) );
}
$CTMP=&NCAR::mpfnme($IAID,2);
$LCTM=&NCAR::mpilnb($CTMP);
printf( STDERR  "    &NCAR::mpfnme($IAID,2) = %s\n", substr( $CTMP, 0, &NCAR::Test::min( 58,$LCTM)) );
if ($LCTM > 58) {
printf( STDERR  "                           %s\n", substr( $CTMP, 58, &NCAR::Test::min(116,$LCTM)-57 ) );
}
$CTMP=&NCAR::mpfnme($IAID,1);
$LCTM=&NCAR::mpilnb($CTMP);
printf( STDERR  "    &NCAR::mpfnme($IAID,1) = %s\n", substr( $CTMP, 0, &NCAR::Test::min( 58,$LCTM)) );
if ($LCTM > 58) {
printf( STDERR  "                           %s\n", substr( $CTMP, 58, &NCAR::Test::min(116,$LCTM)-57 ) );
}
#
# Done.
#
L103:
