#!perl -T
use Test::More;
if($ENV{RELEASE_TESTING}) {
    eval "use Test::Pod::Coverage 1.04";
    plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
    all_pod_coverage_ok();
} else {
    plan skip_all => "We are not running release tests";
}
