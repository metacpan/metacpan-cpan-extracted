use strict;
use Test::More;
use Math::Trig;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Polyline';

use Image::SVG::Transform;
my $transform = Image::SVG::Transform->new();
$transform->extract_transforms('translate(10,10)');

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


is_deeply $polyline->draw_start, [15,13], 'translated polyline start point, first point in line definition';
is_deeply $polyline->draw_end,   [17,17], '... end point, last line';
cmp_ok $polyline->shape_length,  '==',  6.000, '... polyline length';

is $polyline->min_x, 15, 'min_x';
is $polyline->max_x, 17, 'max_x';
is $polyline->min_y, 13, 'min_y';
is $polyline->max_y, 17, 'max_y';

done_testing();
