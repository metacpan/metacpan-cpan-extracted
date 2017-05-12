use Test::More;
plan skip_all => "pod coverage is disabled for now";


eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
#all_pod_coverage_ok();
pod_coverage_ok( "Sprocket");
