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
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
# Fill the data array.
#
my @xycd;

open AGDA, "<data/agda13.dat";
while( <AGDA> ) {
  s/(?:^\s*|\s*$)//go;
  push @xycd, split( /\s+/ );
}
close AGDA;
#
for my $i ( 1..226 ) {
  next if( $xycd[ $i - 1 ] == 1E36 );
  $xycd[ $i - 1 ] = exp( log( 2 ) * ( $xycd[ $i - 1 ] - 15. ) / 2.5 );
}
#
# Specify log/log plot.
#
&NCAR::displa (0,0,4);
#
# Bump the line-maximum parameter past 42.
#
&NCAR::agseti( 'LINE/MAXIMUM.', 50 );
#
# Specify x- and y-axis labels, grid background.
#
&NCAR::anotat('LOGARITHMIC, BASE 2, EXPONENTIAL LABELS$',
              'LOGARITHMIC, BASE 2, NO-EXPONENT LABELS$',
              2,0,0, [ ]);
#
# Specify the graph label.
#
&NCAR::agsetc( 'LABEL/NAME.', 'T' );
&NCAR::agseti( 'LINE/NUMBER.', 100 );
&NCAR::agsetc( 'LINE/TEXT.', 'FINAL EXAMPLE$' );
#
# Specify x-axis ticks and labels.
#
&NCAR::agseti( 'BOTTOM/MAJOR/TYPE.', 3 );
&NCAR::agsetr( 'BOTTOM/MAJOR/BASE.', 2. );
&NCAR::agseti( 'BOTTOM/NUMERIC/TYPE.', 2 );
&NCAR::agseti( 'BOTTOM/MINOR/SPACING.', 4 );
&NCAR::agseti( 'BOTTOM/MINOR/PATTERN.', 43690 );
#
# Specify y-axis ticks and labels.
#
&NCAR::agseti( 'LEFT/MAJOR/TYPE.', 3 );
&NCAR::agsetr( 'LEFT/MAJOR/BASE.', 2. );
&NCAR::agseti( 'LEFT/NUMERIC/TYPE.', 3 );
&NCAR::agseti( 'LEFT/MINOR/SPACING.', 4 );
&NCAR::agseti( 'LEFT/MINOR/PATTERN.', 43690 );
#
# Compute secondary control parameters.
#

my ( @xcd, @ycd );
for my $i ( 1 .. 113 ) {
 $xcd[ $i - 1 ] = $xycd[ 2 * $i - 2 ];
 $ycd[ $i - 1 ] = $xycd[ 2 * $i - 1 ];
}

my $XCD = float( \@xcd );
my $YCD = float( \@ycd );

&NCAR::agstup ( 
                $XCD, 1, 0, 113, 1, 
                $YCD, 1, 0, 113, 1,
              );
#
# Draw the background.
#
&NCAR::agback;
#
# Draw the curve twice to make it darker.
#

&NCAR::agcurv ( $XCD, 1, $YCD, 1,113,1);
&NCAR::agcurv ( $XCD, 1, $YCD, 1,113,1);


&bndary();

&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/agex13.ncgm';
