use Test::More;
plan skip_all => 'TEST_POD_COVERAGE environment required for running this test' unless $ENV{TEST_POD_COVERAGE};
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;
all_pod_coverage_ok({ also_private => [qr/^(BUILD|meta)$/,] });
