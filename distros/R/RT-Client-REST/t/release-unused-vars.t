
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use Test::More 0.96 tests => 1;
use Test::Vars;

subtest 'unused vars' => sub {
all_vars_ok();
};
