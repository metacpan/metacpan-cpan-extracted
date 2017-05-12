use strict;
use Test::More;
use Math::Trig;
use Image::SVG::Transform;
use lib 'lib', '../lib';

my $transform = Image::SVG::Transform->new();
use_ok 'SVG::Estimate::Polygon';

my $points_string = '2,0 2,1 1,1 1,2 2,2 2,3 3,3 3,2 4,2 4,1 3,1 3,0';

my $polygon = SVG::Estimate::Polygon->new(
    start_point => [0,0],
    transformer => $transform,
    points  => $points_string,
);

is_deeply $polygon->draw_start, [2,0], 'polygon start point, dead north';
is_deeply $polygon->draw_end,   [2,0], '... end point, same as the start';
cmp_ok $polygon->shape_length,  '==', 12, 'polygon length';

is $polygon->min_x, 1, 'min_x';
is $polygon->max_x, 4, 'max_x';
is $polygon->min_y, 0, 'min_y';
is $polygon->max_y, 3, 'max_y';

done_testing();
