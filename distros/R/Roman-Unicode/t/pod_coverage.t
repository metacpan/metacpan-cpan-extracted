use Test::More;

my $coverage_module = 'Test::Pod::Coverage';
my $module_version  = 1.04;
eval "use $coverage_module $module_version";

plan skip_all =>
	"You need $coverage_module $module_version to test Pod coverage" if $@;
all_pod_coverage_ok();
