#!perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'Set AUTHOR_TEST to run this test'
    unless $ENV{AUTHOR_TEST};
plan skip_all => 'Test::Pod required'
    unless eval 'use Test::Pod; 1';

all_pod_files_ok();
