use strict;
use Test::More;
use Image::SVG::Transform;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Rect';
##Translate a rectangle
my $transform = Image::SVG::Transform->new();
$transform->extract_transforms('translate (10,-5)');
my $rect = SVG::Estimate::Rect->new(
    start_point => [10,30],
    x           => 0,
    y           => 310,
    width       => 943,
    height      => 741,
    transformer => $transform,
);
isa_ok $rect, 'SVG::Estimate::Rect';

is $rect->round(0.12351), 0.124, 'rounding works';

is $rect->x, 10, 'Checking translated x';
is $rect->y, 305, '... y';
is $rect->width, 943, '... width';
is $rect->height, 741, '... height';

is_deeply $rect->draw_start, [10, 305], 'rectangle draw start';
is_deeply $rect->draw_end,   [10, 305], '... draw end, closed shape, same as start';

is $rect->round($rect->travel_length), $rect->round(275.000), '... travel length';

is $rect->shape_length, 3368, '... shape_length';

is $rect->round($rect->length), $rect->round(3643.000), '... total length';

is $rect->min_x, 10, '... min_x';
is $rect->max_x, 953, '... max_x';
is $rect->min_y, 305, '... min_y';
is $rect->max_y, 1046, '... max_y';

##Flip the rectangle around and check for sanity on the translated coordinates
$transform = Image::SVG::Transform->new();
$transform->extract_transforms('rotate(180 7 7)');
$rect = SVG::Estimate::Rect->new(
    start_point => [7,7],
    x           => 5,
    y           => 5,
    width       => 4,
    height      => 4,
    transformer => $transform,
);
isa_ok $rect, 'SVG::Estimate::Rect';

is $rect->x, 5, 'Checking translated x';
is $rect->y, 5, '... y';
is $rect->width, 4, '... width';
is $rect->height, 4, '... height';

done_testing();

