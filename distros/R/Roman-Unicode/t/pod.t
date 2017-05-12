use Test::More;

my $pod_module  = 'Test::Pod';
my $pod_version = 1.14;

eval "use $pod_module $pod_version";
plan skip_all => "You need $pod_module $pod_version to test Pod" if $@;
all_pod_files_ok();
