use Test::More;
eval "use Test::Pod 1.14";

if ($@) {
    plan skip_all => "Test::Pod 1.14 required for testing POD coverage";
}

all_pod_files_ok();
