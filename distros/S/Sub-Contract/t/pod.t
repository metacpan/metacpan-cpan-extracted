use Test::More;
use lib "../lib/";
use lib "./lib/";
use lib "../";
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
if (all_pod_files()) {
    all_pod_files_ok();
} else {
    plan skip_all => "no modules found";
}
