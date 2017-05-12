#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 20;

use Pinwheel::Helpers::List qw(group enumerate uniq take drop);


# Group list items
{
    is_deeply(group([], 2), []);
    is_deeply(group([10], 2), [[10, undef]]);
    is_deeply(group([10, 20, 30, 40], 2), [[10, 20], [30, 40]]);
    is_deeply(group([10, 20, 30], 2), [[10, 20], [30, undef]]);
}

# Enumerate list items
{
    is_deeply(enumerate([]), []);
    is_deeply(enumerate([10, 20, 30]), [[0, 10], [1, 20], [2, 30]]);
    is_deeply(enumerate([10, 20, 30], 4), [[4, 10], [5, 20], [6, 30]]);
}

# Remove duplicate items
{
    is_deeply(uniq([]), []);	
    is_deeply(uniq([1,1]), [1]);
    is_deeply(uniq([1,2,3]), [1,2,3]);
    is_deeply(uniq([1,2,3,2]), [1,2,3]);
}

# Take first N items
{
    is_deeply(take([], 2), []);
    is_deeply(take([10], 2), [10]);
    is_deeply(take([10, 20], 2), [10, 20]);
    is_deeply(take([10, 20, 30], 2), [10, 20]);
}

# Drop first N items
{
    is_deeply(drop([], 2), []);
    is_deeply(drop([10], 2), []);
    is_deeply(drop([10, 20], 2), []);
    is_deeply(drop([10, 20, 30], 2), [30]);
    is_deeply(drop([10, 20, 30, 40], 2), [30, 40]);
}
