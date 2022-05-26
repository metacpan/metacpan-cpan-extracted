#!/usr/bin/env perl

use Test::Most;
use Test::PerlTidy 'run_tests';

run_tests(
    path       => 'lib',
    perltidyrc => 'xt/perltidyrc',
);
