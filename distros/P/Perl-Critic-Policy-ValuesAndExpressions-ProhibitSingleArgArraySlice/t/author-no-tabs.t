
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
    'lib/Perl/Critic/Policy/ValuesAndExpressions/ProhibitSingleArgArraySlice.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/ValuesAndExpressions/ProhibitSingleArgArraySlice.run',
    't/policies.t'
);

notabs_ok($_) foreach @files;
done_testing;
