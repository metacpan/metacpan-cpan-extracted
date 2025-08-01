
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
    'lib/Net/CIDR/Set.pm',
    'lib/Net/CIDR/Set/IPv4.pm',
    'lib/Net/CIDR/Set/IPv6.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-clean-namespaces.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-mixed-unicode-scripts.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/basic.t',
    't/etc/perlcritic.rc',
    't/ipv6.t',
    't/is_cidr.t',
    't/misc.t',
    't/octal.t',
    't/operations.t',
    't/private.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-fixme.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
