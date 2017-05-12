use strict;
use Test::More;
my $t; use lib ($t = -e 't' ? 't' : '.');
use lib 'lib', '../lib';

use_ok 'SVG::Estimate';
my $onesquare = SVG::Estimate->new( file_path => $t.'/var/onesquare.svg' );
isa_ok $onesquare, 'SVG::Estimate';
$onesquare->estimate;
cmp_ok $onesquare->round($onesquare->length), '==', 1226.979, 'one square - length';
cmp_ok $onesquare->shape_count, '==', 1, 'one square - shape count';
cmp_ok $onesquare->round($onesquare->min_x), '==', 36,  '... min_x';
cmp_ok $onesquare->round($onesquare->max_x), '==', 252, '... max_x';
cmp_ok $onesquare->round($onesquare->min_y), '==', 216, '... min_y';
cmp_ok $onesquare->round($onesquare->max_y), '==', 504, '... max_y';

my $shapes = SVG::Estimate->new( file_path => $t.'/var/shapes.svg' );
$shapes->estimate;
cmp_ok $shapes->length, '>', 5000, 'shapes - length';
cmp_ok $shapes->shape_count, '==', 7, 'shapes - shape count';
cmp_ok $shapes->round($shapes->min_x), '==', 36,  '... min_x';
cmp_ok $shapes->round($shapes->max_x), '==', 687.203, '... max_x';
cmp_ok $shapes->round($shapes->min_y), '==', 39.157, '... min_y';
cmp_ok $shapes->round($shapes->max_y), '==', 518.5, '... max_y';

my $drawing1 = SVG::Estimate->new( file_path => $t.'/var/drawing-1.svg' );
$drawing1->estimate;
cmp_ok $drawing1->length, '>', 200, 'drawing-1 - length';
cmp_ok $drawing1->shape_count, '==', 1, 'shape count';
cmp_ok $drawing1->round($drawing1->min_x), '==', 50,  '... min_x';
cmp_ok $drawing1->round($drawing1->max_x), '==', 100, '... max_x';
cmp_ok $drawing1->round($drawing1->min_y), '==', 50, '... min_y';
cmp_ok $drawing1->round($drawing1->max_y), '==', 100, '... max_y';


my $inkscape_box_in = SVG::Estimate->new( file_path => $t.'/var/inkscape-box-px.svg' );
$inkscape_box_in->estimate;
cmp_ok $inkscape_box_in->round($inkscape_box_in->length), '==', 1333.336, 'inkscape_box_in - length';
cmp_ok $inkscape_box_in->shape_count, '==', 1, 'inkscape_box_in - shape count';

my $affinity_box_in = SVG::Estimate->new( file_path => $t.'/var/affinity-box-in.svg' );
$affinity_box_in->estimate;
cmp_ok $affinity_box_in->round($affinity_box_in->length), '==', 863.998, 'affinity_box_in - length';
cmp_ok $affinity_box_in->shape_count, '==', 1, 'affinity_box_in - shape count';

my $furniture = SVG::Estimate->new( file_path => $t.'/var/furniture.svg' );
$furniture->estimate;
cmp_ok $furniture->round($furniture->length), '==', 44755.084, 'furniture - length';
cmp_ok $furniture->shape_count, '==', 563, 'furniture - shape count';

done_testing();

