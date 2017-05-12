#!perl -T

use Test::More;

if ( $ENV{TEST_POD} || $ENV{TEST_ALL} ) {
    eval "use Test::Pod::Coverage 1.04";
    plan skip_all =>
        "Test::Pod::Coverage 1.04 required for testing POD coverage"
        if $@;
}
else {
    plan skip_all => 'set TEST_POD for testing POD coverage';
}

all_pod_coverage_ok();
