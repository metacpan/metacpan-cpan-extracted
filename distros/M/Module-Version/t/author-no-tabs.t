
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
    'bin/mversion',
    'lib/Module/Version.pm',
    'lib/Module/Version/App.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/app.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/basic.t',
    't/lib/ModuleVersionTester.pm',
    't/lib/include/ModuleVersionTesterInclude.pm',
    't/manifest.t',
    't/more_opts.t',
    't/pod-coverage.t',
    't/pod.t'
);

notabs_ok($_) foreach @files;
done_testing;
