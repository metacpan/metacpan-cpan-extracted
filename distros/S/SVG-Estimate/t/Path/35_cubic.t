use strict;
use Test::More;
use lib 'lib', '../../lib', '../lib';
use Image::SVG::Transform;

use_ok 'SVG::Estimate::Path::CubicBezier';
my $transform = Image::SVG::Transform->new();
$transform->extract_transforms('scale(2)');
my $cubic = SVG::Estimate::Path::CubicBezier->new(
    transformer => $transform,
    start_point    => [120, 160],
    end            => [110, 20],
    control1       => [17.5, 100],
    control2       => [110, 130],
);
isa_ok $cubic, 'SVG::Estimate::Path::CubicBezier';

is_deeply $cubic->start_point, [120, 160], 'cubic bezier start point';
is_deeply $cubic->end_point, [220,40], 'cubic bezier end point';
cmp_ok $cubic->round($cubic->shape_length),  '==', 272.868, 'cubic bezier shape length';
cmp_ok $cubic->round($cubic->travel_length),  '==', 0.0, 'cubic bezier travel length';

cmp_ok $cubic->round($cubic->min_x), '==', 97.665, 'min_x';
cmp_ok $cubic->round($cubic->max_x), '==', 220, 'max_x';
cmp_ok $cubic->round($cubic->min_y), '==', 40, 'min_y';
cmp_ok $cubic->round($cubic->max_y), '==', 198.862, 'max_y';

done_testing();

