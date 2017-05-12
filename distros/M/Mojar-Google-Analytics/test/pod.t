use Mojo::Base -strict;
use Test::More;

plan skip_all => 'set TEST_POD to enable this test (developer only!)'
  unless $ENV{TEST_POD} or $ENV{RELEASE_TESTING};
# Ensure a recent version of Test::Pod
plan skip_all => "Test::Pod 1.22 required for testing POD"
  unless eval 'use Test::Pod 1.22; 1';

all_pod_files_ok();
