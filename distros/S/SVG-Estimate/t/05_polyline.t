use strict;
use Test::More;
use Math::Trig;
use Image::SVG::Transform;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Polyline';

my $transform = Image::SVG::Transform->new();
my $polyline = SVG::Estimate::Polyline->new(
    start_point => [0,0],
    transformer => $transform,
    points      => '5,3 5,4 6,4 6,5 6,6 7,6 7,7',
   # [  ##unit staircase
   #     [5, 3],
   #     [5, 4],
   #     [6, 4],
   #     [6, 5],
   #     [6, 6],
   #     [7, 6],
   #     [7, 7],
   # ],
);


is_deeply $polyline->draw_start, [5,3], 'polyline start point, first point in line definition';
is_deeply $polyline->draw_end,   [7,7], 'polyline end point, last line';
cmp_ok $polyline->shape_length,  '==',  6.000, 'polyline length';

is $polyline->min_x, 5, 'min_x';
is $polyline->max_x, 7, 'max_x';
is $polyline->min_y, 3, 'min_y';
is $polyline->max_y, 7, 'max_y';

my $polyline2 = SVG::Estimate::Polyline->new(
    start_point => [0,0],
    transformer => $transform,
    points      => '5 3 5 4 6 4 6 5 6 6 7 6 7 7' 
   # [  ##unit staircase
   #     [5, 3],
   #     [5, 4],
   #     [6, 4],
   #     [6, 5],
   #     [6, 6],
   #     [7, 6],
   #     [7, 7],
   # ],
);


note "Polyline with no commas";
is_deeply $polyline2->draw_start, [5,3], 'polyline start point, first point in line definition';
is_deeply $polyline2->draw_end,   [7,7], 'polyline end point, last line';
cmp_ok $polyline2->shape_length,  '==',  6.000, 'polyline length';

done_testing();
