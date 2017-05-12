use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@ or !$ENV{BINGOS_TEST};
all_pod_coverage_ok();
