use Test::Arrow;
eval "use Test::Pod 1.14";
Test::Arrow->plan(skip_all => "Test::Pod 1.14 required for testing POD") if $@;
all_pod_files_ok();
