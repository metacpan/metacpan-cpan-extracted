
use Test::More;
BEGIN {
    plan skip_all => 'These tests are for release candidate testing'
      unless $ENV{RELEASE_TESTING};
}
use Test::Pod 1.18;

all_pod_files_ok(all_pod_files('.'));
