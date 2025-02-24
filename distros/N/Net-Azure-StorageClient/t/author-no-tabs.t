
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
    'lib/Net/Azure/StorageClient.pm',
    'lib/Net/Azure/StorageClient/Blob.pm',
    'lib/Net/Azure/StorageClient/Blob/Thread.pm',
    'lib/Net/Azure/StorageClient/MIMEType.pm',
    't/00-Blob.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-clean-namespaces.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-breakpoints.t',
    't/author-no-tabs.t',
    't/author-pod-linkcheck.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-pause-permissions.t',
    't/release-test-legal.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
