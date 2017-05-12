
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoBreakpoints 0.18

use Test::More 0.88;
use Test::NoBreakpoints 0.15;

all_files_no_breakpoints_ok();

done_testing;
