
use Test::More;
plan skip_all => "No Developer Tests for non-developers" unless $ENV{AUTHOR_TESTING};
eval "use Test::Pod 1.18";
plan skip_all => "Test::Pod 1.18 required for testing POD" if $@;

all_pod_files_ok(all_pod_files("."));
