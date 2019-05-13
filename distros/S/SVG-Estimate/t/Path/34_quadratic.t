use strict;
use Test::More;
use lib 'lib', '../../lib', '../lib';
use Image::SVG::Transform;

use_ok 'SVG::Estimate::Path::QuadraticBezier';
my $transform = Image::SVG::Transform->new();
$transform->extract_transforms('translate(2,3)');
my $quad = SVG::Estimate::Path::QuadraticBezier->new(
    transformer => $transform,
    start_point   => [1, 1],
    end           => [4, 3],
    control       => [6, 0.5],
);
isa_ok $quad, 'SVG::Estimate::Path::QuadraticBezier';

is_deeply $quad->start_point, [1, 1], 'quadratic bezier start point';
is_deeply $quad->end_point, [6,6], 'quadratic bezier end point';
cmp_ok $quad->round($quad->shape_length),  '==', 8.219, 'quadratic bezier shape length';
cmp_ok $quad->round($quad->travel_length),  '==', 0.0, 'quadratic bezier travel length';

is $quad->min_x, 1, 'min_x';
is $quad->max_x, 8, 'max_x';
is $quad->min_y, 1, 'min_y';
is $quad->max_y, 6, 'max_y';

done_testing();

