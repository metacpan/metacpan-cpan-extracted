
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.1.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

my @files = (
    'lib/Software/Policy/CodeOfConduct.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/author-clean-namespaces.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-mixed-unicode-scripts.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/etc/perlcritic.rc',
    't/release-check-manifest.t',
    't/release-fixme.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t'
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
