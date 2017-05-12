#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Exception;
use Setup::Project::Functions;


cmp_deeply {equal_style(['a=1', 'b=2'])}, {
    a => 1,
    b => 2,
};

dies_ok { equal_style('a=1 a=2') };

done_testing;
