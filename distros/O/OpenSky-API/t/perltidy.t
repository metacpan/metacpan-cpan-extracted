#!/usr/bin/env perl

use Test::PerlTidy qw( run_tests );
run_tests(
    path       => 'lib',
    perltidyrc => 't/perltidyrc',
);
