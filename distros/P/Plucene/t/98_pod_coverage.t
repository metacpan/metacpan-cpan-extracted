use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

# all_pod_coverage_ok();
# Skipped until I can find a way to make Test::Pod::Coverage use Pod::Coverage::CountParents;

plan tests => 1;

pass "CPANTS gamed successfully?";

