use Test::More;

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage required for testing 98_pod.t" if $@;
all_pod_coverage_ok();

# use Test::Pod::Coverage tests=>2;
# pod_coverage_ok( "Su", "Su is covered" );
# pod_coverage_ok( "Su::Log", "Su is covered" );

