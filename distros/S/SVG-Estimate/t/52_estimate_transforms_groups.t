use strict;
use Test::More;
my $t; use lib ($t = -e 't' ? 't' : '.');
use lib 'lib', '../lib';

use_ok 'SVG::Estimate';

my $without = SVG::Estimate->new( file_path => $t.'/var/groups-without-transforms.svg' );
$without->estimate;
my $with    = SVG::Estimate->new( file_path => $t.'/var/groups-with-transforms.svg' );
$with->estimate;

cmp_ok abs($with->length - $without->length), '<=', 0.05 * $with->length,   'comparing equivalent SVGs with and without transforms, length';

cmp_ok $with->round($with->shape_count), '==', $without->round($without->shape_count), '... shape count';
cmp_ok $with->round($with->min_x),       '==', $without->round($without->min_x),       '... min_x';
cmp_ok $with->round($with->max_x),       '==', $without->round($without->max_x),       '... max_x';
cmp_ok $with->round($with->min_y),       '==', $without->round($without->min_y),       '... min_y';
cmp_ok $with->round($with->max_y),       '==', $without->round($without->max_y),       '... max_y';

done_testing();

