use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Physics::Etch::GDSII;

# --- 8-byte real codec round-trip ------------------------------------------
for my $v ( 1e-3, 1e-9, 1.0, -2.5, 90, 0.25, 123456.789 ) {
    my $dec = Physics::Etch::GDSII::_real8_decode(
        Physics::Etch::GDSII::_real8_encode($v) );
    my $rel = $v ? abs( ( $dec - $v ) / $v ) : abs($dec);
    ok( $rel < 1e-12, "real8 round-trip $v (rel err $rel)" );
}
is( Physics::Etch::GDSII::_real8_decode(
        Physics::Etch::GDSII::_real8_encode(0) ),
    0, 'real8 zero' );

# --- write / read a boundary -----------------------------------------------
my $tmp = "$FindBin::Bin/_gdsii_test.gds";
my $g   = Physics::Etch::GDSII->new( libname => 'T', user_unit => 1e-6, db_unit => 1e-9 );
$g->add_rectangle( 'CELL', layer => 7, x => 0, y => 0, width => 2, height => 4 );
$g->add_sref( 'TOP', sname => 'CELL', x => 10, y => 0 );
$g->add_aref( 'TOP', sname => 'CELL', x => 0, y => 20,
    cols => 3, rows => 2, col_pitch => 5, row_pitch => 5 );
$g->add_sref( 'TOP', sname => 'CELL', x => 0, y => 50, angle => 90 );
$g->write($tmp);
ok( -s $tmp, 'gdsii file written' );

my $in = Physics::Etch::GDSII->read($tmp);
is( $in->libname, 'T', 'libname round-trip' );
ok( abs( $in->db_unit - 1e-9 ) < 1e-18,  'db_unit round-trip' );
ok( abs( $in->user_unit - 1e-6 ) < 1e-15, 'user_unit round-trip' );

# top cell auto-detect
is( $in->_top_structure, 'TOP', 'top cell detected' );

# flatten: 1 sref + (3x2 aref) + 1 rotated sref = 8 polygons on layer 7
my @p = $in->polygons( layer => 7, unit => 'um' );
is( scalar @p, 8, 'flattened polygon count (sref + aref + rotated)' );

# none on a different layer
is( scalar( $in->polygons( layer => 99 ) ), 0, 'layer filter works' );

# check the first sref rectangle geometry (2x4 at x=10)
my ($rect) = grep {
    my @xs = map { $_->[0] } @$_;
    ( sort { $a <=> $b } @xs )[0] == 10;
} @p;
ok( $rect, 'found translated rectangle at x=10' );
{
    my @xs = map { $_->[0] } @$rect;
    my @ys = map { $_->[1] } @$rect;
    my $w  = ( sort { $b <=> $a } @xs )[0] - ( sort { $a <=> $b } @xs )[0];
    my $h  = ( sort { $b <=> $a } @ys )[0] - ( sort { $a <=> $b } @ys )[0];
    ok( abs( $w - 2 ) < 1e-6 && abs( $h - 4 ) < 1e-6, 'rectangle size 2x4 um' );
}

# rotated (90 deg) rectangle should be 4 wide x 2 tall
my ($rot) = grep {
    my @ys = map { $_->[1] } @$_;
    ( sort { $a <=> $b } @ys )[0] >= 49;      # placed at y=50
} @p;
ok( $rot, 'found rotated rectangle' );
{
    my @xs = map { $_->[0] } @$rot;
    my @ys = map { $_->[1] } @$rot;
    my $w  = ( sort { $b <=> $a } @xs )[0] - ( sort { $a <=> $b } @xs )[0];
    my $h  = ( sort { $b <=> $a } @ys )[0] - ( sort { $a <=> $b } @ys )[0];
    ok( abs( $w - 4 ) < 1e-6 && abs( $h - 2 ) < 1e-6, '90-deg rotation swaps w/h' );
}

unlink $tmp;
done_testing;
