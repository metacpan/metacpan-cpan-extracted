#!perl -T
# $RedRiver: pod-coverage.t,v 1.2 2007/02/24 01:29:22 andrew Exp $

use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;
all_pod_coverage_ok();
