# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
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

my ( @xdra, @ydra );
my @dshp;
my $agdshn;

for my $i ( 1..101 ) {
  push @xdra, -90. + 1.8 * ( $i - 1 );
}

for my $j ( 1..9 ) {
  push @dshp, sprintf( '$$$$$$$$$$$$$$$$$$$$$\'J\'=\'%1d\'', $j );
  my $fj = $j;
  for my $i ( 1..101 ) {
    push @ydra, 3. * $fj - ( $fj / 2700. ) * $xdra[$i-1] * $xdra[$i-1];
#   $ydra[ $i - 1 ][ $j - 1 ] = 3. * $fj - ( $fj / 2700. ) 
#                             * $xdra[$i-1] * $xdra[$i-1];
  }
}

&NCAR::agseti( 'WINDOWING.', 1 );
&NCAR::agsetr( 'GRID/LEFT.', .10 );
&NCAR::agsetr( 'GRID/RIGHT.', .90 );
&NCAR::agsetr( 'GRID/BOTTOM.', .10 );
&NCAR::agsetr( 'GRID/TOP.', .85 );

# Set the x and y minimum and maximum.

&NCAR::agsetr( 'X/MINIMUM.', -90. );
&NCAR::agsetr( 'X/MAXIMUM.', +90. );
&NCAR::agsetr( 'Y/MINIMUM.', 0. );
&NCAR::agsetr( 'Y/MAXIMUM.', 18. );

# Set left axis parameters.

&NCAR::agseti( 'LEFT/MAJOR/TYPE.', 1 );
&NCAR::agsetr( 'LEFT/MAJOR/BASE.', 3. );
&NCAR::agseti( 'LEFT/MINOR/SPACING.', 2 );

# Set right axis parameters.

&NCAR::agseti( 'RIGHT/FUNCTION.', 1 );
&NCAR::agsetr( 'RIGHT/NUMERIC/TYPE.', 1.E36 );

# Set bottom axis parameters.

&NCAR::agseti( 'BOTTOM/MAJOR/TYPE.', 1 );
&NCAR::agsetr( 'BOTTOM/MAJOR/BASE.', 15. );
&NCAR::agseti( 'BOTTOM/MINOR/SPACING.', 2 );

# Set top axis parameters.

&NCAR::agseti( 'TOP/FUNCTION.', 2 );
&NCAR::agsetr( 'TOP/NUMERIC/TYPE.', 1.E36 );

# Set up the dash patterns to be used.

&NCAR::agseti( 'DASH/SELECTOR.', 9 );
&NCAR::agseti( 'DASH/LENGTH.', 28 );


# Set up the left label.

&NCAR::agsetc( 'LABEL/NAME.', 'L' );
&NCAR::agseti( 'LINE/NUMBER.', 100 );
&NCAR::agsetc( 'LINE/TEXT.', 'HEIGHT (KILOMETERS)$' );

# Set up the right label.

&NCAR::agsetc( 'LABEL/NAME.', 'R' );
&NCAR::agseti( 'LINE/NUMBER.', -100 );
&NCAR::agsetc( 'LINE/TEXT.', 'PRESSURE (TONS/SQUARE FURLONG)$' );

# Set up the bottom labels.

&NCAR::agsetc( 'LABEL/NAME.', 'B' );
&NCAR::agseti( 'LINE/NUMBER.', -100 );
&NCAR::agsetc( 'LINE/TEXT.', 'LATITUDE (DEGREES)$' );

&NCAR::agsetc( 'LABEL/NAME.', 'SP' );
&NCAR::agsetr( 'LABEL/BASEPOINT/X.', .000001 );
&NCAR::agsetr( 'LABEL/BASEPOINT/Y.', 0. );
&NCAR::agsetr( 'LABEL/OFFSET/Y.', -.015 );
&NCAR::agseti( 'LINE/NUMBER.', -100 );
&NCAR::agsetc( 'LINE/TEXT.', 'SP$' );

&NCAR::agsetc( 'LABEL/NAME.', 'NP' );
&NCAR::agsetr( 'LABEL/BASEPOINT/X.', .999999 );
&NCAR::agsetr( 'LABEL/BASEPOINT/Y.', 0. );
&NCAR::agsetr( 'LABEL/OFFSET/Y.', -.015 );
&NCAR::agseti( 'LINE/NUMBER.', -100 );
&NCAR::agsetc( 'LINE/TEXT.', 'NP$' );

# Set up the top label.

&NCAR::agsetc( 'LABEL/NAME.', 'T' );
&NCAR::agseti( 'LINE/NUMBER.', 80 );
&NCAR::agsetc( 'LINE/TEXT.', 'DISTANCE FROM EQUATOR (MILES)$' );
&NCAR::agseti( 'LINE/NUMBER.', 90 );
&NCAR::agsetc( 'LINE/TEXT.', ' $' );
&NCAR::agseti( 'LINE/NUMBER.', 100 );
&NCAR::agsetc( 'LINE/TEXT.', 'LINES OF CONSTANT INCRUDESCENCE$' );
&NCAR::agseti( 'LINE/NUMBER.', 110 );
&NCAR::agsetc( 'LINE/TEXT.', 'EXAMPLE 7 (EZMXY)$' );

# Set up centered (box 6) label.

&NCAR::agsetc( 'LABEL/NAME.', 'EQUATOR' );
&NCAR::agseti( 'LABEL/ANGLE.', 90 );
&NCAR::agseti( 'LINE/NUMBER.', 0 );
&NCAR::agsetc( 'LINE/TEXT.', 'EQUATOR$' );

# Draw a boundary around the edge of the plotter frame.

&BNDARY();

# Draw the graph, using EZMXY.

&NCAR::ezmxy( float( \@xdra ), float( \@ydra ), 101, 9, 101, '' );

sub BNDARY {
&NCAR::plotit(     0,     0, 0 );
&NCAR::plotit( 32767,     0, 1 );
&NCAR::plotit( 32767, 32767, 1 );
&NCAR::plotit(     0, 32767, 1 );
&NCAR::plotit(     0,     0, 1 );
}

sub Log10 {
  my $x = shift;
  return log( $x ) / log( 10 );
}

sub NCAR::agutol {
  my ($IAXS,$FUNS,$IDMA,$VINP,$VOTP) = @_;
#
# Mapping for the right axis.
#
  if( $FUNS == 1 ) {
    if( $IDMA > 0 ) { $VOTP = Log10( 20.-$VINP ); }
    if( $IDMA < 0 ) { $VOTP = 20 - exp( log( 10 ) * $VINP ); }
#
# Mapping for the top axis.
#
  } elsif( $FUNS == 2 ) {
    if( $IDMA > 0 ) { $VOTP=70.136*$VINP; }
    if( $IDMA < 0 ) { $VOTP=$VINP/70.136; }
#
# Default (identity) mapping.
#
  } else {
    $VOTP=$VINP;
  }
  $_[4] = $VOTP;
}


&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();


rename 'gmeta', 'ncgm/agex07.ncgm';
