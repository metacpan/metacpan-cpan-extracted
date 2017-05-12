use strict;
use warnings FATAL => 'all';
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all =>
  "Test::Pod::Coverage $min_tpc required for testing POD coverage"
  if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
  if $@;
all_pod_coverage_ok(
    {
        trustme => [
            qw/add_data all_numerical copy get_aoa get_aoa_by_lab get_aref_by_lab get_data get_hoa_by_lab get_hoa_by_lab_numonly_indep get_hoa_by_lab_numonly_across labels load_data load_from_file load_from_path read save save_to_file save_to_path update/
        ]
    }
);

1;
