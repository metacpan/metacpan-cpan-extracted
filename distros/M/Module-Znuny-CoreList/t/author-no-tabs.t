
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
    'lib/Module/Znuny/CoreList.pm',
    'lib/Module/Znuny/CoreList.pod',
    't/001_shipped.t',
    't/002_changed_tickets_dashboard.t',
    't/003_modules.t',
    't/004_cpan.t'
);

notabs_ok($_) foreach @files;
done_testing;
