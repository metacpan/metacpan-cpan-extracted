use Test::More;
use Data::Dumper;

eval "use Test::Pod 1.00";

plan skip_all => "Test::Pod 1.00 required for testing 99_pod.t" if $@;
diag "Checking pod.";
diag Dumper( all_pod_files() );
all_pod_files_ok();

