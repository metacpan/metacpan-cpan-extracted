#!/usr/bin/env perl
#
# Generate a sample GDSII mask (examples/sample_mask.gds) with a mix of feature
# sizes and pattern densities, for the loading / anisotropy simulation examples.
#
#   layer 1 = resist openings (clear tone)
#   - a dense grating of 0.25 um lines   (RIE-lag / micro-loading region)
#   - isolated 0.5, 1 and 2 um lines
#   - a large 10 um contact pad          (macro-loading contributor)

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Physics::Etch::GDSII;

my $file = shift || "$FindBin::Bin/sample_mask.gds";

my $g = Physics::Etch::GDSII->new(
    libname   => 'ETCH_SAMPLE',
    user_unit => 1e-6,      # micron
    db_unit   => 1e-9,      # nm
);

# reusable line cells (width um x 40 um tall), on layer 1
for my $w ( 0.25, 0.5, 1.0, 2.0 ) {
    ( my $name = sprintf( 'L%03d', $w * 100 ) );
    $g->add_rectangle( $name, layer => 1, x => 0, y => 0,
        width => $w, height => 40 );
}

# TOP: place the features across a 200 x 200 um field
# dense 0.25 um grating (40 lines, 0.5 um pitch) -> ~50% local density
$g->add_aref( 'TOP', sname => 'L025', x => 5, y => 10,
    cols => 40, rows => 1, col_pitch => 0.5, row_pitch => 1 );
# 0.5 um lines, medium pitch
$g->add_aref( 'TOP', sname => 'L050', x => 60, y => 10,
    cols => 10, rows => 1, col_pitch => 2, row_pitch => 1 );
# isolated 1 um lines
$g->add_aref( 'TOP', sname => 'L100', x => 90, y => 10,
    cols => 6, rows => 1, col_pitch => 5, row_pitch => 1 );
# isolated 2 um lines
$g->add_aref( 'TOP', sname => 'L200', x => 130, y => 10,
    cols => 4, rows => 1, col_pitch => 8, row_pitch => 1 );
# large 10 um pad
$g->add_rectangle( 'TOP', layer => 1, x => 170, y => 10,
    width => 10, height => 40 );

$g->write($file);
printf "Wrote %s (%d bytes)\n", $file, -s $file;
