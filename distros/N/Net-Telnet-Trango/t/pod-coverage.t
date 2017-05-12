#!perl -T
# $RedRiver: pod-coverage.t,v 1.1 2007/02/05 18:10:55 andrew Exp $

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
