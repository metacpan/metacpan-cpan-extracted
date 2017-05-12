use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;

pod_coverage_ok($_) for grep !/:PP$/, all_modules();

done_testing;
