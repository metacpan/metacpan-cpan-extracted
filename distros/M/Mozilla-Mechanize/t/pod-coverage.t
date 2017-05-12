#!/usr/bin/perl -Tw
use Test::More;
eval "use Test::Pod::Coverage 1.04";

if ($ENV{USER} ne 'slanning') {
    plan skip_all => 'POD coverage tests are intended for developers';
}
elsif ($@) {
    plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage: $@";
}
else {
    plan skip_all => "I'm too lazy to test POD coverage";
    #all_pod_coverage_ok();
}
