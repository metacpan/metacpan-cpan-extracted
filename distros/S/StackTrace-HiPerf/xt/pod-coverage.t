#!/usr/bin/perl

use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing pod coverage"
  if $@;
all_pod_coverage_ok();
