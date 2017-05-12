#!perl -T

use Test::More;
plan skip_all => "set RELEASE_TESTING to test POD" unless $ENV{RELEASE_TESTING};
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();


