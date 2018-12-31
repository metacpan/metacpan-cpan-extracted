#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::Interval::Barycentric';

is_deeply [barycenter(3)], [4,4,4], 'barycenter';

is distance([4,3,5], [4,4,4]), 1, 'distance=1';
is distance([2,4,6], [4,4,4]), 2, 'distance=2';
is distance([1,1,10], [4,4,4]), 3*sqrt(3), 'distance=3*sqrt(3)';
is distance([4,3,5], [1,3,8]), 3, 'distance=3';
is sprintf('%.3f', distance([2,3,1,6], [2,1,3,7])), 2.121, 'distance=2.121';

is orbit_distance([4,3,5], [3,4,5]), 1, 'orbit_distance=1';

#TODO is forte_distance(), 1, 'forte_distance';

is_deeply [cyclic_permutation(2,4,6)],
    [ [2,4,6], [6,2,4], [4,6,2] ],
    'cyclic_permutation';

is evenness_index([4,3,5]), 1, 'evenness_index=1';
is evenness_index([2,4,6]), 2, 'evenness_index=2';

done_testing;
