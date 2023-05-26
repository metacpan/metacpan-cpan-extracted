
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoBOM 0.002

use Test::More 0.88;
use Test::BOM;

my @files = (
    'lib/OPM/Maker/Command/depcheck.pm',
    't/001_base.t',
    't/002_all_ok.t',
    't/003_cpan_fails.t',
    't/004_local_sopm.t',
    't/005_invalid_home.t',
    't/006_no_sopm.t',
    't/lib/NotYetThere.sopm',
    't/lib/depcheck.pm'
);

ok(file_hasnt_bom($_)) for @files;

done_testing;
