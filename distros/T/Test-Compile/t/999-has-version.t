#!perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'Set AUTHOR_TEST to run this test'
    unless $ENV{AUTHOR_TEST};
plan skip_all => 'Test::HasVersion required'
    unless eval 'use Test::HasVersion; 1';

all_pm_version_ok();
