# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print'

use Test;
BEGIN { plan tests => 1 }
use NCAR;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
unlink( 'gmeta' );

use PDL;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

my @xdra, @ydra;

#
# Fill the data arrays.
#

for( my $i = 1; $i <= 101; $i ++ ) {
   push @xdra, -3.14159265358979 +
               .062831853071796 * ( $i - 1 );
}

#

for( my $i = 1; $i <= 4; $i++ ) {
  my $base = 2. * $i - 1;
  for( my $j = 1; $j < 101; $j++ ) {
    $ydra[ $j - 1 ][ $i - 1 ] = $base + .75 * sin( -3.14159265358979 +
                            .062831853071796 * $i * ( $j - 1 ) );
  }
}

#
# Change the line-end character to a period.
#
&NCAR::agsetc( 'LINE/END.', '.' );
#
# Specify labels for x and y axes.
#
&NCAR::anotat ('SINE FUNCTIONS OF T.','T.',0,0,0, [ ] );
#
# Use a half-axis background.
#
&NCAR::agseti( 'BACKGROUND.', 3 );
#
# Move x axis to the zero point on the y axis.
#
&NCAR::agsetr( 'BOTTOM/INTERSECTION/USER.', 0. );
#
# Specify base value for spacing of major ticks on x axis.
#
&NCAR::agsetr( 'BOTTOM/MAJOR/BASE.', 1. );
#
# Run major ticks on x axis to edge of curve window.
#
&NCAR::agsetr( 'BOTTOM/MAJOR/INWARD.', 1. );
&NCAR::agsetr( 'BOTTOM/MAJOR/OUTWARD.', 1. );
#
# Position x axis minor ticks.
#
&NCAR::agseti( 'BOTTOM/MINOR/SPACING.', 9 );
#
# Run the y axis backward.
#
&NCAR::agseti( 'Y/ORDER.', 1 );
#
# Run plots full-scale in y.
#
&NCAR::agseti( 'Y/NICE.', 0 );
#
# Have AUTOGRAPH scale x and y data the same.
#
&NCAR::agsetr( 'GRID/SHAPE.', .01 );
#
# Use the alphabetic set of dashed-line patterns.
#
&NCAR::agseti( 'DASH/SELECTOR.', -1 );
#
# Tell AUTOGRAPH how the data arrays are dimensioned.
#
&NCAR::agseti( 'ROW.', -1 );
#
# Reverse the roles of the x and y arrays.
#
&NCAR::agseti( 'INVERT.', 1 );
#
# Draw a boundary around the edge of the plotter frame.
#
&bndary;
#
# Draw the curves.
#
&NCAR::ezmxy ( float( \@xdra ), float( \@ydra ), 4, 4, 101, 'EXAMPLE 8.' );
#


sub bndary {;
&NCAR::plotit(     0,     0, 0 );
&NCAR::plotit( 32767,     0, 1 );
&NCAR::plotit( 32767, 32767, 1 );
&NCAR::plotit(     0, 32767, 1 );
&NCAR::plotit(     0,     0, 1 );
};

&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();


rename 'gmeta', 'ncgm/agex08.ncgm';
