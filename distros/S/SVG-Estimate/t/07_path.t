use strict;
use Test::More;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Path';
use Image::SVG::Transform;

my $transform = Image::SVG::Transform->new();
my $path = SVG::Estimate::Path->new(
    transformer => $transform,
    start_point => [0,0],
    d  => 'M 5 5 L 5 15 L 15 15 L 15 5 Z',
);

#foreach my $command (@{ $path->commands }) {
#    diag ref $command;
#    diag explain $command->start_point;
#    diag explain $command->point;
#    diag $command->length;
#}

is scalar(@{$path->commands}), 5, 'All commands correctly parsed';
is_deeply $path->draw_start, [5,5], 'start drawing at the first command (always a moveto)';
cmp_ok $path->round($path->shape_length),  '==', 40.0, 'simple path length';  ##Shape length includes the travel_length due to the moveto
##Test travel_length and length to make sure we don't count the initial moveto twice
cmp_ok $path->round($path->travel_length), '==', 7.071, 'path travel length';
cmp_ok $path->min_x, '==',  5, '... min x';
cmp_ok $path->max_x, '==', 15, '... max x';
cmp_ok $path->min_y, '==',  5, '... min y';
cmp_ok $path->max_y, '==', 15, '... max y';

my $path2 = SVG::Estimate::Path->new(
    transformer => $transform,
    start_point => [0,0],
    d  => 'M 1 1 L 2 2 M 3 3',
);
cmp_ok $path2->round($path2->shape_length),  '==', 1.414, 'two moves, simple path length';
cmp_ok $path2->round($path2->travel_length), '==', 2.828, '... path travel length';
is_deeply $path2->draw_end, [3, 3], 'checking end point of a path';

done_testing();
