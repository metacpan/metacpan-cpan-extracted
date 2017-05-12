#!perl -w

# $Id: pod-coverage.t 977 2004-12-17 17:30:37Z theory $

use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.06";
plan skip_all => "Test::Pod::Coverage 1.06 required for testing POD coverage"
  if $@;

all_pod_coverage_ok();
