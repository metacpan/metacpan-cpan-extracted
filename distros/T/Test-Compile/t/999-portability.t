#!perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'Set AUTHOR_TEST to run this test'
    unless $ENV{AUTHOR_TEST};
plan skip_all => 'Test::Portability::Files required'
    unless eval 'use Test::Portability::Files; 1';

run_tests();
