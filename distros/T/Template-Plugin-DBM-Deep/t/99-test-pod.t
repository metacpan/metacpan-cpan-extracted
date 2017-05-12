#!perl
use Test::More;
plan skip_all => "Test::Pod 1.00 required for testing POD"
  unless eval "use Test::Pod 1.00; 1";

$ENV{TEST_VERBOSE}
  or plan 'skip_all' => 'Distribution tests selected only in verbose mode';

all_pod_files_ok();


