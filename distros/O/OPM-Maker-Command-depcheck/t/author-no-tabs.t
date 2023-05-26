
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
