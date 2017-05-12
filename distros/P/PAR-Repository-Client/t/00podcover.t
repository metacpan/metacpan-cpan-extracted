#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
plan skip_all => "Set environment variable PERL_TEST_POD=1 to test POD"
  if not $ENV{PERL_TEST_POD};
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
  if $@;
all_pod_coverage_ok();

