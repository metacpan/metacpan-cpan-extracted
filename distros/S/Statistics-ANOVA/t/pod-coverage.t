use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok({trustme => ['add_data', 'aov', 'cluster', 'delete_data', 'levene_test', 'load_data', 'obrien_test']});
1;