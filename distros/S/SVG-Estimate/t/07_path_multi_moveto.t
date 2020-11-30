use strict;
use Test::More;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Path';
use Image::SVG::Transform;

{
    my $transform = Image::SVG::Transform->new();
    my $path = SVG::Estimate::Path->new(
        transformer => $transform,
        start_point => [0,0],
        d  => 'm 5 5 1 0 0 1 -1 0 0 -1',
    );

    is scalar(@{$path->commands}), 5, 'All commands correctly parsed';
    is_deeply $path->draw_start, [5,5], 'start drawing at the first command (always a moveto)';
    cmp_ok $path->round($path->shape_length),  '==', 4, 'simple path length';  ##Shape length includes the travel_length due to the moveto
    ##Test travel_length and length to make sure we don't count the initial moveto twice
    cmp_ok $path->round($path->travel_length), '==', 7.071, 'path travel length';
    cmp_ok $path->min_x, '==', 5, '... min x';
    cmp_ok $path->max_x, '==', 6, '... max x';
    cmp_ok $path->min_y, '==', 5, '... min y';
    cmp_ok $path->max_y, '==', 6, '... max y';
}

{
    my $transform = Image::SVG::Transform->new();
    my $path = SVG::Estimate::Path->new(
        transformer => $transform,
        start_point => [0,0],
        d  => 'm 1 0 1 0 0 1 -1 0 z m 2 0 1 0 0 1 -1 0 z',
    );

    is scalar(@{$path->commands}), 10, 'All commands correctly parsed, multiple close paths';
    is_deeply $path->draw_start, [1,0], 'start drawing at the first command (always a moveto)';
    cmp_ok $path->round($path->shape_length),  '==', 8, 'simple path length';
    ##Test travel_length and length to make sure we don't count the initial moveto twice
    cmp_ok $path->round($path->travel_length), '==', 3, 'path travel length';
    cmp_ok $path->min_x, '==', 1, '... min x';
    cmp_ok $path->max_x, '==', 4, '... max x';
    cmp_ok $path->min_y, '==', 0, '... min y';
    cmp_ok $path->max_y, '==', 1, '... max y';
}

done_testing();
