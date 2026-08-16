#!perl

use strict;
use warnings;
use Test::More;

plan skip_all => 'Author test; set AUTHOR_TESTING=1 to run'
    unless $ENV{AUTHOR_TESTING};

eval 'use Test::Pod 1.41';
plan skip_all => 'Test::Pod 1.41 required for this test' if $@;

all_pod_files_ok();
