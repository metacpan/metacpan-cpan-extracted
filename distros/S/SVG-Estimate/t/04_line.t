use strict;
use Test::More;
use Math::Trig;
use Image::SVG::Transform;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Line';

my $transform = Image::SVG::Transform->new();

my $line = SVG::Estimate::Line->new(
    x1          => 12,
    y1          => 147,
    x2          => 58,
    y2          => 226,
    start_point => [11, 450],
    transformer => $transform,
);

is_deeply $line->draw_start, [12, 147], 'line start point';
is_deeply $line->draw_end, [58,226], 'line end point';
cmp_ok $line->round($line->shape_length),  '==', 91.417, 'line length';

is $line->min_x, 12,  'min_x';
is $line->max_x, 58,  'max_x';
is $line->min_y, 147, 'min_y';
is $line->max_y, 226, 'max_y';

my $line2 = SVG::Estimate::Line->new(
    x1          => 10,
    y1          => 10,
    x2          => 9,
    y2          => 9,
    start_point => [11, 450],
    transformer => $transform,
);

is $line2->min_x, 9,  'backwards line, min_x';
is $line2->max_x, 10, 'backwards line, max_x';
is $line2->min_y, 9,  'backwards line, min_y';
is $line2->max_y, 10, 'backwards line, max_y';

done_testing();
