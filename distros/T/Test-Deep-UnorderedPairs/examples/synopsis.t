use strict;
use warnings;

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Deep::UnorderedPairs;

cmp_deeply(
    {
        inventory => [
            pear => 6,
            peach => 5,
            apple => 1,
        ],
    },
    {
        inventory => unordered_pairs(
            apple => 1,
            peach => ignore,
            pear => 6,
        ),
    },
    'got the right inventory',
);

done_testing;
