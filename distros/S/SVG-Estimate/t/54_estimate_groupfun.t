use strict;
use Test::More;
my $t; use lib ($t = -e 't' ? 't' : '.');
use lib 'lib', '../lib';

use_ok 'SVG::Estimate';

my $onesquare = SVG::Estimate->new( file_path => $t.'/var/onesquare.svg' );
isa_ok $onesquare, 'SVG::Estimate';
$onesquare->estimate;
cmp_ok $onesquare->round($onesquare->length), '==', 1226.979, 'one square - length';
cmp_ok $onesquare->shape_count, '==', 1, '... shape count';
cmp_ok $onesquare->round($onesquare->min_x), '==', 36,  '... min_x';
cmp_ok $onesquare->round($onesquare->max_x), '==', 252, '... max_x';
cmp_ok $onesquare->round($onesquare->min_y), '==', 216, '... min_y';
cmp_ok $onesquare->round($onesquare->max_y), '==', 504, '... max_y';

my $onesq_g = SVG::Estimate->new( file_path => $t.'/var/group-onesquare.svg' );
isa_ok $onesq_g, 'SVG::Estimate';
$onesq_g->estimate;
cmp_ok $onesq_g->round($onesq_g->length), '==', 1226.979, 'group with one square - length';
cmp_ok $onesq_g->shape_count, '==', 1, '... shape count';
cmp_ok $onesq_g->round($onesq_g->min_x), '==', 36,  '... min_x';
cmp_ok $onesq_g->round($onesq_g->max_x), '==', 252, '... max_x';
cmp_ok $onesq_g->round($onesq_g->min_y), '==', 216, '... min_y';
cmp_ok $onesq_g->round($onesq_g->max_y), '==', 504, '... max_y';

my $onesq_gp = SVG::Estimate->new( file_path => $t.'/var/group-prop-onesquare.svg' );
isa_ok $onesq_gp, 'SVG::Estimate';
$onesq_gp->estimate;
cmp_ok $onesq_gp->round($onesq_gp->length), '==', 1226.979, 'group with property and one square - length';
cmp_ok $onesq_gp->shape_count, '==', 1, '... shape count';
cmp_ok $onesq_gp->round($onesq_gp->min_x), '==', 36,  '... min_x';
cmp_ok $onesq_gp->round($onesq_gp->max_x), '==', 252, '... max_x';
cmp_ok $onesq_gp->round($onesq_gp->min_y), '==', 216, '... min_y';
cmp_ok $onesq_gp->round($onesq_gp->max_y), '==', 504, '... max_y';

my $onesq_gg = SVG::Estimate->new( file_path => $t.'/var/group-group-onesquare.svg' );
isa_ok $onesq_gg, 'SVG::Estimate';
$onesq_gg->estimate;
cmp_ok $onesq_gg->round($onesq_gg->length), '==', 1226.979, 'group - group - one square - length';
cmp_ok $onesq_gg->shape_count, '==', 1, '... shape count';
cmp_ok $onesq_gg->round($onesq_gg->min_x), '==', 36,  '... min_x';
cmp_ok $onesq_gg->round($onesq_gg->max_x), '==', 252, '... max_x';
cmp_ok $onesq_gg->round($onesq_gg->min_y), '==', 216, '... min_y';
cmp_ok $onesq_gg->round($onesq_gg->max_y), '==', 504, '... max_y';

my $onesq_ge = SVG::Estimate->new( file_path => $t.'/var/group-prop-empty.svg' );
isa_ok $onesq_ge, 'SVG::Estimate';
$onesq_ge->estimate;
cmp_ok $onesq_ge->round($onesq_ge->length), '==', 0.0, 'group - property - empty - length';
cmp_ok $onesq_ge->shape_count, '==', 0, '... shape count';

done_testing();

