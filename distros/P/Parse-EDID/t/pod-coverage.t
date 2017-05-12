#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

eval { require Test::Pod::Coverage; };
plan(skip_all => 'Test::Pod::Coverage required') if $EVAL_ERROR;


Test::Pod::Coverage->import();
all_pod_coverage_ok();
