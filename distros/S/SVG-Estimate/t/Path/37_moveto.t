use strict;
use Test::More;
use lib 'lib', '../../lib', '../lib';
use Image::SVG::Transform;

use_ok 'SVG::Estimate::Path::Moveto';
my $transform = Image::SVG::Transform->new();
$transform->extract_transforms('translate (10,-5)');
my $moveto = SVG::Estimate::Path::Moveto->new(
    transformer => $transform,
    start_point => [4, 5],
    point       => [14, 15],
);
isa_ok $moveto, 'SVG::Estimate::Path::Moveto';

is_deeply $moveto->start_point, [4, 5], 'moveto start point';
is_deeply $moveto->end_point, [24,10], 'moveto end point';
cmp_ok $moveto->round($moveto->travel_length),  '==', 20.616, 'moveto travel length';
cmp_ok $moveto->round($moveto->shape_length),   '==', 0.0, 'moveto shape length';

is $moveto->min_x, 24, 'min_x';
is $moveto->max_x, 24, 'max_x';
is $moveto->min_y, 10, 'min_y';
is $moveto->max_y, 10, 'max_y';

done_testing();
