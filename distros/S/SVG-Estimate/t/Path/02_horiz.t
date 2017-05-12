use strict;
use Test::More;
use lib 'lib', '../../lib', '../lib';
use Image::SVG::Transform;

use_ok 'SVG::Estimate::Path::HorizontalLineto';
my $transform = Image::SVG::Transform->new();
my $hlineto = SVG::Estimate::Path::HorizontalLineto->new(
    transformer => $transform,
    start_point => [4, 5],
    x => 14,
);

is_deeply $hlineto->end_point, [14,5], 'horizontallineto end point';
is_deeply $hlineto->start_point, [4, 5], 'checking that we did not stomp on the starting point';
cmp_ok $hlineto->round($hlineto->shape_length),  '==', 10, 'horizontallineto shape length';
cmp_ok $hlineto->round($hlineto->travel_length),  '==', 0, 'horizontallineto travel length';

is $hlineto->min_x, 4, 'min_x';
is $hlineto->max_x, 14, 'max_x';
is $hlineto->min_y,  5, 'min_y';
is $hlineto->max_y,  5, 'max_y';

done_testing();
