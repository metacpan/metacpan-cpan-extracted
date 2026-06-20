
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        print qq{1..0 # SKIP these tests are for testing by the author\n};
        exit;
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'Build.PL',
    'Changes',
    'LICENSE',
    'META.json',
    'META.yml',
    'Makefile.PL',
    'README',
    'cpanfile',
    'lib/Perl/Critic/Policy/Misc/ProhibitMethodsInStringConcat.pm',
    't/.perlcriticrc',
    't/00-compile.t',
    't/01-policy.t',
    't/Misc/ProhibitMethodsInStringConcat.run',
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
    't/check-warnings.pl',
    't/release-kwalitee.t',
    't/release-pause-permissions.t',
    't/release-test-legal.t',
    't/release-unused-vars.t'
);

eol_unix_ok( $_, { trailing_whitespace => 1 } ) foreach @files;
done_testing;
