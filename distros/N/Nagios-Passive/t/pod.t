#!perl

use Test::More;

plan skip_all => 'author test' unless $ENV{RELEASE_TESTING};

eval "use Test::Pod 1.14";
if ( $@ ) {
  plan skip_all => "Test::Pod 1.14 required for testing POD"
}
all_pod_files_ok();
