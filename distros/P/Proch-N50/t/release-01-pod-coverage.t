
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;
use Test::More;
eval "use Test::Pod::Coverage 1.10";
plan skip_all => "Test::Pod::Coverage 1.10 required for testing POD coverage" if $@;
all_pod_coverage_ok();
