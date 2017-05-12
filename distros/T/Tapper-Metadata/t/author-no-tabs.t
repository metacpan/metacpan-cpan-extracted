
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
    'lib/Tapper/Metadata.pm',
    'lib/Tapper/Metadata/Query.pm',
    'lib/Tapper/Metadata/Query/SQLite.pm',
    'lib/Tapper/Metadata/Query/default.pm',
    'lib/Tapper/Metadata/Query/mysql.pm',
    'lib/Tapper/Metadata/Testrun.pm',
    't/00-load.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/tapper-metadata_testrun_sqlite.t'
);

notabs_ok($_) foreach @files;
done_testing;
