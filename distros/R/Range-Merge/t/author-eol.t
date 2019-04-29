
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Range/Merge.pm',
    'lib/Range/Merge/Boilerplate.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-use.t',
    't/02-basic-merge.t',
    't/03-basic-merge-with-data.t',
    't/04.cidrs.t',
    't/05.discrete.t',
    't/author-01-full-bgp-table.t',
    't/author-02-full-bgp-cidr.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/data/convert-to-range.pl',
    't/data/level3-full-from-routeviews.txt',
    't/data/level3-ranges-from-routeviews.txt',
    't/data/nm1.in',
    't/data/nm1.out',
    't/data/nm2.in',
    't/data/nm2.out',
    't/data/nm3.in',
    't/data/nm3.out',
    't/data/nm3a.in',
    't/data/nm3a.out',
    't/data/nm3b.in',
    't/data/nm3b.out',
    't/data/nm4.in',
    't/data/nm4.out',
    't/data/nm4a.in',
    't/data/nm4a.out',
    't/data/nm5.in',
    't/data/nm5.out',
    't/data/nm6.in',
    't/data/nm6.out',
    't/data/nm7.in',
    't/data/nm7.out',
    't/data/nm7a.in',
    't/data/nm7a.out',
    't/data/nm7b.in',
    't/data/nm7b.out',
    't/data/nm8.in',
    't/data/nm8.out',
    't/data/perlcriticrc',
    't/release-changes_has_content.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
