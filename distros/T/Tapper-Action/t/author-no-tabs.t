
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
    'bin/tapper-action',
    'bin/tapper-action-daemon',
    'lib/Tapper/Action.pm',
    'lib/Tapper/Action/Daemon.pm',
    'lib/Tapper/Action/Plugin/resume/OSRC.pm',
    'lib/Tapper/Action/Plugin/updategrub/OSRC.pm',
    't/00-load.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/bin/reset_testfile',
    't/files/grubfile',
    't/fixtures/testrundb/testrun_with_preconditions.yml',
    't/misc_files/sleep.sh',
    't/pod-coverage.t',
    't/pod.t',
    't/release-pod-coverage.t',
    't/tapper-action.t',
    't/tapper.cfg'
);

notabs_ok($_) foreach @files;
done_testing;
