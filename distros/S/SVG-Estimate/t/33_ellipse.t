use strict;
use Test::More;
use Image::SVG::Transform;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Ellipse';

my $transform = Image::SVG::Transform->new();
$transform->extract_transforms('translate(100,100) scale(2)');
my $ellipse = SVG::Estimate::Ellipse->new(
    cx          => 3,
    cy          => 3,
    rx          => 10,
    ry          => 5,
    start_point => [0,0],
    transformer => $transform,
);

is_deeply $ellipse->draw_start, [126,106], 'ellipse start point, dead north';
is_deeply $ellipse->draw_end,   [126,106], '... end point, dead north';
cmp_ok $ellipse->round($ellipse->shape_length),  '==', 95.787, '... circumerence';

is $ellipse->min_x,  86, '... min_x';
is $ellipse->max_x, 126, '... max_x';
is $ellipse->min_y,  96, '... min_y';
is $ellipse->max_y, 116, '... max_y';

done_testing();
