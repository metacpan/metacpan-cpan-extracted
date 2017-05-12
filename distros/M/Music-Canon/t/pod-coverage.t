#!perl
use 5.010000;
use Test::Most;

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

# probably should figure up how to Pod::Coverage-compatible-POD up the not-
# BUILD attribute thingies here... (olden perl versions fail on "new" method
# that Moo makes, so put in an exception for that)
all_pod_coverage_ok(
  { trustme => [
      qr/BUILD|atonal|get_contrary|get_modal_chrome|get_retrograde|get_transpose|has_modal_in|has_modal_out|has_modal_scale_in|has_modal_scale_out|new/
    ]
  }
);
