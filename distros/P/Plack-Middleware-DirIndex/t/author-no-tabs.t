
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
    'lib/Plack/Middleware/DirIndex.pm',
    't/add_dir.t',
    't/app.t',
    't/app_tests.pl',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/root/404.html',
    't/root/index.html',
    't/root/other/alt.html',
    't/root/other/no_index_here.txt'
);

notabs_ok($_) foreach @files;
done_testing;
