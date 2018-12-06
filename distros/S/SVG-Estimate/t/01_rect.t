use strict;
use Test::More;
use Image::SVG::Transform;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Rect';
my $transform = Image::SVG::Transform->new();
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

is_deeply $rect->draw_start, [0,310], 'rectangle draw start';
is_deeply $rect->draw_end,   [0,310], 'rectangle end is the same as the start';

is $rect->round($rect->travel_length), 280.179, 'rectangle travel length';

is $rect->shape_length, 3368, 'rectangle length';

is $rect->round($rect->length), 3648.179, 'rectangle total length';

is $rect->min_x, 0, 'min_x';
is $rect->max_x, 943, 'max_x';
is $rect->min_y, 310, 'min_y';
is $rect->max_y, 1051, 'max_y';

my $origin = SVG::Estimate::Rect->new(
    start_point => [1,1],
    width       => 5,
    height      => 5,
    transformer => $transform,
);
isa_ok $origin, 'SVG::Estimate::Rect';
is $origin->x, 0, 'default x';
is $origin->y, 0, '... y';
is $origin->min_x, 0, 'Rect with no x,y default to 0,0';

my $line = SVG::Estimate::Rect->new(
    start_point => [1,1],
    x       => 1,
    y       => 1,
    width   => 10,
    height  => 0,
    transformer => $transform,
);
isa_ok $line, 'SVG::Estimate::Rect';
is $line->shape_length, 0, 'not rendered means 0 shape length';

done_testing();

