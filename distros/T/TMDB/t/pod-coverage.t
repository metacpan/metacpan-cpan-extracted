use warnings;
use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

TODO: {
  local $TODO = 'Add missing documentation';
  all_pod_coverage_ok();
}
