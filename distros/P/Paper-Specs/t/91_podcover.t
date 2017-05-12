use Test::More;
eval "use Test::Pod::Coverage 0.08";
plan skip_all => "Test::Pod::Coverage 0.08 required for testing POD coverage" if $@;

plan tests => 1;
pod_coverage_ok("Paper::Specs");
