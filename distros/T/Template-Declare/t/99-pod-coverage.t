use Test::More;

# XXX we need more POD...
my $skip_all = 1;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;
plan skip_all => "Coverage tests only run for authors" unless (-d 'inc/.author');
all_pod_coverage_ok();

