
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Tapper/Reports/DPath.pm',
    'lib/Tapper/Reports/DPath/Mason.pm',
    'lib/Tapper/Reports/DPath/TT.pm',
    't/00-load.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/dpath_mason.t',
    't/dpath_tt.t',
    't/dpath_tt_utilmethods.t',
    't/fixtures/testrundb/report.yml',
    't/helloworld.mas',
    't/helloworld.tt',
    't/path.t',
    't/pod-coverage.t',
    't/pod.t',
    't/tapper_reports_dpath.t'
);

notabs_ok($_) foreach @files;
done_testing;
