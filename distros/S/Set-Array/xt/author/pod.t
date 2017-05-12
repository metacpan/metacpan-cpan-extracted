use Test::More;

eval "use Test::Pod 1.45";

plan skip_all => "Test::Pod 1.45 required for testing POD" if $@;

all_pod_files_ok();
