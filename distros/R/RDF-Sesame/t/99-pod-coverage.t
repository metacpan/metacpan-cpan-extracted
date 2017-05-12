use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
    if $@ || $ENV{MINIMAL_TEST};

all_pod_coverage_ok(
    {trustme => [qw( new )]}
);
