
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print "1..0 # SKIP these tests are for testing by the author\n";
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Net/Works.pm',
    'lib/Net/Works/Address.pm',
    'lib/Net/Works/Network.pm',
    'lib/Net/Works/Role/IP.pm',
    'lib/Net/Works/Types.pm',
    'lib/Net/Works/Util.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Address.t',
    't/Network-splitting.t',
    't/Network.t',
    't/author-00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-synopsis.t',
    't/author-test-version.t',
    't/bad-data.t',
    't/release-cpan-changes.t',
    't/release-tidyall.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
