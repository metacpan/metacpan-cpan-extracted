#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::Interval::Barycentric';

is_deeply [barycenter(3)], [4,4,4], 'barycenter';

is distance([4,3,5], [4,4,4]), 1, 'distance';
is distance([2,4,6], [4,4,4]), 2, 'distance';
is sprintf('%.3f', distance([1,1,10], [4,4,4])), 5.196, 'distance';
is distance([4,3,5], [1,3,8]), 3, 'distance';
is sprintf('%.3f', distance([2,3,1,6], [2,1,3,7])), 2.121, 'distance';

is orbit_distance([4,3,5], [3,4,5]), 1, 'orbit_distance';
is orbit_distance([4,3,5], [4,4,4]), 1, 'orbit_distance';
is sprintf('%.3f', orbit_distance([1,1,10], [4,4,4])), 5.196, 'orbit_distance';
is orbit_distance([4,3,5], [1,3,8]), 3, 'orbit_distance';
is sprintf('%.3f', orbit_distance([2,3,1,6], [2,1,3,7])), 2.121, 'orbit_distance';

is forte_distance([4,3,5], [3,4,5]), 0, 'forte_distance';
is forte_distance([4,3,5], [4,3,5]), 0, 'forte_distance';
is forte_distance([4,3,5], [4,4,4]), 1, 'forte_distance';
is forte_distance([2,4,6], [4,4,4]), 2, 'forte_distance';
is sprintf('%.3f', forte_distance([2,3,1,6], [2,1,3,7])), 1.871, 'forte_distance';

is_deeply [cyclic_permutation(2,4,6)],
    [ [2,4,6], [6,2,4], [4,6,2] ],
    'cyclic_permutation';

is evenness_index([4,3,5]), 1, 'evenness_index';
is evenness_index([2,4,6]), 2, 'evenness_index';

done_testing();
