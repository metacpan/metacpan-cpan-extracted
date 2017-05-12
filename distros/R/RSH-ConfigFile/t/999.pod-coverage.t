#!perl -w

use Test::More tests => 1;
eval "use Test::Pod::Coverage 1.04";
SKIP :{
    skip "Test::Pod::Coverage 1.04 required for testing POD coverage", 1, if $@;
    skip 'set TEST_POD to enable this test', 1,  unless $ENV{TEST_POD};

    pod_coverage_ok("RSH::ConfigFile");
    #pod_coverage_ok("RSH::LockFile");
    #pod_coverage_ok("RSH::SmartHash");
};

#plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
#all_pod_coverage_ok();
