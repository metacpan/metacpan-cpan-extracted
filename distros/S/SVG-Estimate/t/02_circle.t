use strict;
use Test::More;
use Image::SVG::Transform;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Circle';

my $transform = Image::SVG::Transform->new();
my $circle = SVG::Estimate::Circle->new(
    cx          => 2,
    cy          => 2,
    r           => 1,
    start_point => [0,0],
    transformer => $transform,
);

is_deeply $circle->draw_start, [3,2], 'circle draw start';
is_deeply $circle->draw_end,   [3,2], '... draw end';
cmp_ok $circle->round($circle->shape_length),  '==', 6.283, '... circumerence';
cmp_ok $circle->round($circle->travel_length),  '==', 3.606, '... travel length';

is $circle->min_x, 1, 'min_x';
is $circle->max_x, 3, 'max_x';
is $circle->min_y, 1, 'min_y';
is $circle->max_y, 3, 'max_y';

done_testing();
