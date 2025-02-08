
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;
use Test::More;
eval "use Test::Pod 1.51";
plan skip_all => "Test::Pod 1.51 required for testing POD" if $@;
all_pod_files_ok();
