#!/usr/bin/env perl
#
# gdsii.t - tests for Physics::Electrodeposition::GDSII (reader/writer/flatten)
#
use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Physics::Electrodeposition::GDSII;

my $tmp = "$RealBin/_gdsii_tmp.gds";

#--- 8-byte GDSII real encode/decode round-trip -------------------------------
for my $v (1.0, 1e-3, 1e-9, 0.5, 3.14159, 12345.678) {
    my $back = Physics::Electrodeposition::GDSII::_real8(
               Physics::Electrodeposition::GDSII::_to_real8($v));
    ok(abs($back - $v) <= 1e-9 * ($v || 1), "real8 round-trip $v (got $back)");
}
is(Physics::Electrodeposition::GDSII::_real8(
   Physics::Electrodeposition::GDSII::_to_real8(0)), 0, 'real8 zero');

#--- writer/reader round-trip: coordinates and units --------------------------
my @polys = (
    { layer => 1, pts => [[0,0],[10,0],[10,10],[0,10]] },       # 10x10 um
    { layer => 1, pts => [[100,100],[130,100],[130,120],[100,120]] }, # 30x20
    { layer => 2, pts => [[0,0],[5,0],[5,5],[0,5]] },           # other layer
);
Physics::Electrodeposition::GDSII->write_boundaries($tmp, \@polys);
ok(-s $tmp, 'GDSII file written');

my $g = Physics::Electrodeposition::GDSII->new(file => $tmp);
is($g->{meters_per_dbu}, 1e-9, 'database unit read back as 1 nm');
my $p = $g->polygons;
is(scalar @$p, 3, 'read back 3 polygons');

# check the second polygon's bounding box (30 x 20 um at (100,100))
my ($poly) = grep { @{$_->{pts}} && abs($_->{pts}[0][0]-100) < 1e-6 } @$p;
ok($poly, 'found the (100,100) polygon');
my @xs = map { $_->[0] } @{$poly->{pts}};
my @ys = map { $_->[1] } @{$poly->{pts}};
my ($x0,$x1) = (sort { $a <=> $b } @xs)[0,-1];
my ($y0,$y1) = (sort { $a <=> $b } @ys)[0,-1];
ok(abs(($x1-$x0) - 30) < 1e-6, 'width 30 um preserved');
ok(abs(($y1-$y0) - 20) < 1e-6, 'height 20 um preserved');

# layer filtering via top-level polygon layers
my @l1 = grep { $_->{layer} == 1 } @$p;
my @l2 = grep { $_->{layer} == 2 } @$p;
is(scalar @l1, 2, 'two polygons on layer 1');
is(scalar @l2, 1, 'one polygon on layer 2');

#--- hierarchy: AREF flattening (3 cols x 2 rows of a 2x2 um square) -----------
# hand-build a hierarchical stream to exercise SREF/AREF + transforms.
sub rec { my ($rt,$dt,$d)=@_; pack('n',4+length($d)).pack('C',$rt).pack('C',$dt).$d }
sub r8  { Physics::Electrodeposition::GDSII::_to_real8($_[0]) }
my @t = (2025,1,1,0,0,0);
my $buf = '';
$buf .= rec(0x00,2,pack('s>',600));
$buf .= rec(0x01,2,pack('s>*',(@t)x2));
$buf .= rec(0x02,6,"LIB\0");
$buf .= rec(0x03,5, r8(1e-3).r8(1e-9));
$buf .= rec(0x05,2,pack('s>*',(@t)x2));
$buf .= rec(0x06,6,"CELLA\0");
$buf .= rec(0x08,0,'');
$buf .= rec(0x0d,2,pack('s>',7));                       # LAYER 7
$buf .= rec(0x0e,2,pack('s>',0));
$buf .= rec(0x10,3,pack('l>*',0,0, 2000,0, 2000,2000, 0,2000, 0,0));  # 2x2um
$buf .= rec(0x11,0,'');
$buf .= rec(0x07,0,'');
$buf .= rec(0x05,2,pack('s>*',(@t)x2));
$buf .= rec(0x06,6,"TOP\0\0\0");
$buf .= rec(0x0b,0,'');                                 # AREF
$buf .= rec(0x12,6,"CELLA\0");
$buf .= rec(0x13,2,pack('s>*',3,2));                    # 3 cols, 2 rows
$buf .= rec(0x10,3,pack('l>*', 0,0, 30000,0, 0,20000)); # 10um pitches
$buf .= rec(0x11,0,'');
$buf .= rec(0x07,0,'');
$buf .= rec(0x04,0,'');
my $hf = "$RealBin/_gdsii_hier.gds";
open(my $fh,'>:raw',$hf) or die $!; print $fh $buf; close $fh;

my $gh = Physics::Electrodeposition::GDSII->new(file => $hf);
is(join(',', $gh->top_structures), 'TOP', 'TOP is the only top cell');
my $hp = $gh->polygons;
is(scalar @$hp, 6, 'AREF flattened to 6 instances');
is($hp->[0]{layer}, 7, 'child layer preserved through hierarchy');

# verify the six origins land on the expected 10 um grid
my %seen;
for my $poly (@$hp) {
    my @gx = sort { $a <=> $b } map { $_->[0] } @{$poly->{pts}};
    my @gy = sort { $a <=> $b } map { $_->[1] } @{$poly->{pts}};
    $seen{ sprintf('%d,%d', $gx[0], $gy[0]) } = 1;
}
my $expect = join('|', sort ('0,0','10,0','20,0','0,10','10,10','20,10'));
is(join('|', sort keys %seen), $expect, 'array instances at correct positions');

unlink $tmp, $hf;
done_testing();
