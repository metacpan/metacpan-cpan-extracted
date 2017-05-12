use strict;
use warnings;
use Test::More;

eval "use Test::Pod 1.18";
plan skip_all => 'Test::Pod 1.18 required' if $@;
plan skip_all => 'set RELEASE_TESTING to enable this test' unless $ENV{RELEASE_TESTING};
all_pod_files_ok();
