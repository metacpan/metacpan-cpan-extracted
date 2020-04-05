#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::Interval::Barycentric';

is_deeply [barycenter(3)], [4,4,4], 'barycenter';

my @chords = (
    [[4,3,5], [4,3,5]],          # 0
    [[4,3,5], [3,4,5]],
    [[4,3,5], [4,4,4]],
    [[2,4,6], [4,4,4]],          # 3
    [[1,1,10], [4,4,4]],
    [[4,3,5], [1,3,8]],
    [[2,3,1,6], [2,1,3,7]],      # 6
    [[2,4,6], [6,2,4], [4,6,2]],
    [[3,4,5], [0,4,7]],
    [[3,4,5], [5,3,4], [4,5,3]], # 9
);

is distance(@{ $chords[0] }), 0, 'distance';
is distance(@{ $chords[1] }), 1, 'distance';
is distance(@{ $chords[2] }), 1, 'distance';
is distance(@{ $chords[3] }), 2, 'distance';
is sprintf('%.3f', distance(@{ $chords[4] })), 5.196, 'distance';
is distance(@{ $chords[5] }), 3, 'distance';
is sprintf('%.3f', distance(@{ $chords[6] })), 2.121, 'distance';
is sprintf('%.3f', distance(@{ $chords[7] })), 3.464, 'distance';

is orbit_distance(@{ $chords[0] }), 0, 'orbit_distance';
is orbit_distance(@{ $chords[1] }), 1, 'orbit_distance';
is orbit_distance(@{ $chords[2] }), 1, 'orbit_distance';
is orbit_distance(@{ $chords[3] }), 2, 'orbit_distance';
is sprintf('%.3f', orbit_distance(@{ $chords[4] })), 5.196, 'orbit_distance';
is orbit_distance(@{ $chords[5] }), 3, 'orbit_distance';
is sprintf('%.3f', orbit_distance(@{ $chords[6] })), 2.121, 'orbit_distance';
is orbit_distance(@{ $chords[7] }), 0, 'orbit_distance';

is forte_distance(@{ $chords[0] }), 0, 'forte_distance';
is forte_distance(@{ $chords[1] }), 0, 'forte_distance';
is forte_distance(@{ $chords[2] }), 1, 'forte_distance';
is forte_distance(@{ $chords[3] }), 2, 'forte_distance';
is sprintf('%.3f', forte_distance(@{ $chords[4] })), 5.196, 'forte_distance';
is sprintf('%.3f', forte_distance(@{ $chords[5] })), 2.646, 'forte_distance';
is sprintf('%.3f', forte_distance(@{ $chords[6] })), 1.871, 'forte_distance';
is forte_distance(@{ $chords[7] }), 0, 'forte_distance';

is_deeply [cyclic_permutation(@{ $chords[3][0] })],
    $chords[7],
    'cyclic_permutation';
is_deeply [cyclic_permutation(@{ $chords[8][0] })],
    $chords[9],
    'cyclic_permutation';

is evenness_index($chords[0][0]), 1, 'evenness_index';
is evenness_index($chords[2][1]), 0, 'evenness_index';
is evenness_index($chords[3][0]), 2, 'evenness_index';
is sprintf('%.3f', evenness_index($chords[4][0])), 5.196, 'evenness_index';
is sprintf('%.3f', evenness_index($chords[5][1])), 3.606, 'evenness_index';
is sprintf('%.3f', evenness_index($chords[6][0])), 2.646, 'evenness_index';
is sprintf('%.3f', evenness_index($chords[6][1])), '3.240', 'evenness_index';
is evenness_index($chords[7][0]), 2, 'evenness_index';
is evenness_index($chords[7][1]), 2, 'evenness_index';
is evenness_index($chords[7][2]), 2, 'evenness_index';
is evenness_index($chords[8][0]), 1, 'evenness_index';
is sprintf('%.3f', evenness_index($chords[8][1])), 3.536, 'evenness_index';

is_deeply inversion($chords[0][0]), [5,3,4], 'inversion';
is_deeply inversion($chords[6][0]), [6,1,3,2], 'inversion';

done_testing();
