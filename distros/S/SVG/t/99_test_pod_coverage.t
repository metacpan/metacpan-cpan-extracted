use Test::More;

plan skip_all => 'Set $ENV{TEST_AUTHOR} to enable this test.'
    unless $ENV{TEST_AUTHOR};

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage"
    if $@;
plan tests => 1;
pod_coverage_ok("SVG");
