#!perl
use Test::More;
plan skip_all => "Test::Pod::Coverage required for testing POD"
  unless eval "use Test::Pod::Coverage; 1";

$ENV{TEST_VERBOSE}
  or plan 'skip_all' => 'Distribution tests selected only in verbose mode';

all_pod_coverage_ok();
