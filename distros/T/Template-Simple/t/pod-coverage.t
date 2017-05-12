#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
print "ERR [$@]\n";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
