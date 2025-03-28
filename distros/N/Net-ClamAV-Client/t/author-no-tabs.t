
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
    'lib/Net/ClamAV/Client.pm',
    'lib/Net/ClamAV/Exception/Command.pm',
    'lib/Net/ClamAV/Exception/Connect.pm',
    'lib/Net/ClamAV/Exception/Other.pm',
    'lib/Net/ClamAV/Exception/Result.pm',
    'lib/Net/ClamAV/Exception/Unsupported.pm',
    't/00-compile.t',
    't/author-communication.t',
    't/author-critic.t',
    't/author-distmeta.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-synopsis.t',
    't/author-test-version.t',
    't/release-dist-manifest.t',
    't/release-kwalitee.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
