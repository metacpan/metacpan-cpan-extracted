
use Test::More;

BEGIN {
    plan skip_all => 'These tests are for release candidate testing'
      unless $ENV{RELEASE_TESTING};
}
use Test::Pod::Coverage 1.04;

all_pod_coverage_ok();
