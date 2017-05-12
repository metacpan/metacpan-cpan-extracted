use strict;
use Test::More;
use lib 'lib', '../../lib', '../lib';
use Image::SVG::Transform;

use_ok 'SVG::Estimate::Path::Lineto';
my $transform = Image::SVG::Transform->new();
my $lineto = SVG::Estimate::Path::Lineto->new(
    transformer => $transform,
    start_point => [4, 5],
    point => [14, 15],
);
isa_ok $lineto, 'SVG::Estimate::Path::Lineto';

is_deeply $lineto->start_point, [4, 5], 'lineto start point';
is_deeply $lineto->end_point, [14,15], 'lineto end point';
cmp_ok $lineto->round($lineto->shape_length),  '==', 14.142, 'lineto shape length';
cmp_ok $lineto->round($lineto->travel_length), '==', 0.0,    'lineto travel length';

is $lineto->min_x, 4, 'min_x';
is $lineto->max_x, 14, 'max_x';
is $lineto->min_y, 5, 'min_y';
is $lineto->max_y, 15, 'max_y';

done_testing();
