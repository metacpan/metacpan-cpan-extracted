use Test2::V0;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;
foreach my $module (grep {
    $_ ne 'Test2::Compare::Type' &&
    $_ ne 'Test2::Tools::Type::Extras'
} all_modules()) {
    pod_coverage_ok($module);
}
done_testing();
