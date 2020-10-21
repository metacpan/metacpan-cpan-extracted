use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;
pod_coverage_ok('Sub::Rate');
pod_coverage_ok('Sub::Rate::NoMaxRate', { also_private => ['max_rate'] });
done_testing;
