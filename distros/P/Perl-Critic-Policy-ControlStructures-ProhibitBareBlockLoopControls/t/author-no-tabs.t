
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        print qq{1..0 # SKIP these tests are for testing by the author\n};
        exit;
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'Build.PL',
    'Changes',
    'LICENSE',
    'META.json',
    'META.yml',
    'Makefile.PL',
    'README',
    'cpanfile',
    'lib/Perl/Critic/Policy/ControlStructures/ProhibitBareBlockLoopControls.pm',
    't/00-compile.t',
    't/ControlStructures/ProhibitBareBlockLoopControls.run',
    't/author-clean-namespaces.t',
    't/author-critic.t',
    't/author-distmeta.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-breakpoints.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/explanation-messages.t',
    't/perlcritic-policy.t',
    't/release-kwalitee.t',
    't/release-pause-permissions.t',
    't/release-test-legal.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
