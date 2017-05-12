use strict;
use Test::More;
use Image::SVG::Transform;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Ellipse';

my $transform = Image::SVG::Transform->new();
my $ellipse = SVG::Estimate::Ellipse->new(
    cx          => 3,
    cy          => 3,
    rx          => 10,
    ry          => 5,
    start_point => [0,0],
    transformer => $transform,
);

is_deeply $ellipse->draw_start, [13,3], 'ellipse start point, dead east';
is_deeply $ellipse->draw_end, [13,3], '... end point, dead east';
cmp_ok $ellipse->round($ellipse->shape_length),  '==', 48.442, 'ellipse circumerence';

is $ellipse->min_x, -7, 'min_x';
is $ellipse->max_x, 13, 'max_x';
is $ellipse->min_y, -2, 'min_y';
is $ellipse->max_y, 8, 'max_y';

done_testing();
