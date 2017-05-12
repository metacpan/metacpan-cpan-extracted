use strict;
use Test::More;
use Image::SVG::Transform;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Circle';

my $transform = Image::SVG::Transform->new();
$transform->extract_transforms('scale(4)');
my $circle = SVG::Estimate::Circle->new(
    cx          => 2,
    cy          => 2,
    r           => 1,
    start_point => [10,10],
    transformer => $transform,
);

is_deeply $circle->draw_start, [12,8], 'circle draw start';
cmp_ok $circle->round($circle->shape_length),  '==', 24.847, '... circumerence';

is $circle->round($circle->min_x), $circle->round(4),  'min_x';
is $circle->round($circle->max_x), $circle->round(12), 'max_x';
is $circle->round($circle->min_y), $circle->round(4),  'min_y';
is $circle->round($circle->max_y), $circle->round(12), 'max_y';

done_testing();
