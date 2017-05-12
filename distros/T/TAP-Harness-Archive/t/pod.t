#!perl -T
use Test::More;
if ($ENV{RELEASE_TESTING}) {
    eval "use Test::Pod 1.14";
    plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
    all_pod_files_ok();
} else {
    plan skip_all => "We are not running release tests";
}
