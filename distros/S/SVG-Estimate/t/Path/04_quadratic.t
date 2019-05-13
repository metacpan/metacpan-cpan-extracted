use strict;
use Test::More;
use lib 'lib', '../../lib', '../lib';
use Image::SVG::Transform;

use_ok 'SVG::Estimate::Path::QuadraticBezier';
my $transform = Image::SVG::Transform->new();
my $quad = SVG::Estimate::Path::QuadraticBezier->new(
    transformer => $transform,
    start_point   => [0, 0],
    end           => [6, 0],
    control       => [3, 6],
);
isa_ok $quad, 'SVG::Estimate::Path::QuadraticBezier';

is_deeply $quad->start_point, [0, 0], 'quadratic bezier start point';
is_deeply $quad->end_point, [6,0], 'quadratic bezier end point';
cmp_ok $quad->round($quad->shape_length),   '==', 8.873, 'quadratic bezier shape length';
cmp_ok $quad->round($quad->travel_length),  '==', 0.0, 'quadratic bezier travel length';

is $quad->min_x, 0, 'min_x';
is $quad->max_x, 6, 'max_x';
is $quad->min_y, 0, 'min_y';
is $quad->max_y, 6, 'max_y';

my $quad2 = SVG::Estimate::Path::QuadraticBezier->new(
    transformer => $transform,
    start_point   => [1, 1],
    end           => [1, 3],
    control       => [1, 2],
);
isa_ok $quad2, 'SVG::Estimate::Path::QuadraticBezier';

is_deeply $quad2->start_point, [1, 1], 'quadratic bezier start point';
is_deeply $quad2->end_point, [1,3], 'quadratic bezier end point';

is_deeply $quad2->this_point({
                start_point => $quad2->start_point,
                point       => $quad2->end_point,
                control     => $quad2->control,
          }, 0),
          [1, 1],
          'Calculated QB start point, t=0'
;

is_deeply $quad2->this_point({
                start_point => $quad2->start_point,
                point       => $quad2->end_point,
                control     => $quad2->control,
          }, 1),
          [1, 3],
          'Calculated QB end point, t=1'
;


cmp_ok $quad2->round($quad2->shape_length),   '==', 2, 'quadratic bezier shape length';
cmp_ok $quad2->round($quad2->travel_length),  '==', 0.0, 'quadratic bezier travel length';

is $quad2->min_x, 1, 'min_x';
is $quad2->max_x, 1, 'max_x';
is $quad2->min_y, 1, 'min_y';
is $quad2->max_y, 3, 'max_y';

done_testing();

