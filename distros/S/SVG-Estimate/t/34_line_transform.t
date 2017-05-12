use strict;
use Test::More;
use Math::Trig;
use Image::SVG::Transform;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Line';

my $transform = Image::SVG::Transform->new();
$transform->extract_transforms('scale(10)');

my $line = SVG::Estimate::Line->new(
    x1          => 10,
    y1          => 10,
    x2          => 11,
    y2          => 11,
    start_point => [9, 9],
    transformer => $transform,
);

is_deeply $line->draw_start, [100, 100], 'scaled line start point';
is_deeply $line->draw_end,    [110,110], '... end point';
cmp_ok $line->round($line->shape_length),  '==', 14.142, '... line length';

$transform->extract_transforms('translate(5,15)');
$line = SVG::Estimate::Line->new(
    x1          => 10,
    y1          => 10,
    x2          => 20,
    y2          => 20,
    start_point => [0, 0],
    transformer => $transform,
);

is_deeply $line->draw_start, [15, 25], 'translated line start point';
is_deeply $line->draw_end,   [25, 35], '... end point';

done_testing();
