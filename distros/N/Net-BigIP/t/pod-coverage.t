#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

plan(skip_all => 'Author test, set $ENV{AUTHOR_TESTING} to a true value to run')
    if !$ENV{AUTHOR_TESTING};

eval { require Test::Pod::Coverage; };
plan(skip_all => 'Test::Pod::Coverage required') if $EVAL_ERROR;

Test::Pod::Coverage->import();
all_pod_coverage_ok();
