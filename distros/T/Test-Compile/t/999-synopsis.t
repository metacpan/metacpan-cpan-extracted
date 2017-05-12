#!perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'Set AUTHOR_TEST to run this test'
    unless $ENV{AUTHOR_TEST};
plan skip_all => 'Test::Synopsis required'
    unless eval 'use Test::Synopsis; 1';

all_synopsis_ok();
