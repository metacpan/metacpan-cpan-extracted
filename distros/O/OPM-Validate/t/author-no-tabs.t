
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
    'bin/validate_opm',
    'lib/OPM/Validate.pm',
    't/001_base.t',
    't/002_sopm.t',
    't/bad/OnePointElevenBad-6.0.1.opm',
    't/bad/QuickMergeInvalid-3.3.3.opm',
    't/good/AdminEmailTest-6.0.1.opm',
    't/good/CustomerWarnAndErr.sopm',
    't/good/MultiSMTP.sopm',
    't/good/OnePointEleven-6.0.1.opm',
    't/good/ProductNews-5.0.9.opm',
    't/good/ProductNewsDatabaseInstall-5.0.9.opm',
    't/good/QuickMergeOtobo-4.0.3.opm',
    't/good/TestSMTP.sopm',
    't/good/minimal.opm',
    't/good/packagemerge.opm'
);

notabs_ok($_) foreach @files;
done_testing;
