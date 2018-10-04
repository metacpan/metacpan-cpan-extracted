
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
    'lib/Perl/Critic/Policy/Modules/ProhibitUseLib.pm', 't/author-critic.t',
    't/author-no-tabs.t',                               't/author-pod-coverage.t',
    't/author-pod-syntax.t',                            't/data/module.pm',
    't/data/module.pm~',                                't/data/program.pl',
    't/data/program.pl~',                               't/release-changes_has_content.t',
    't/violation_count.t',                              't/violation_count.t~'
);

notabs_ok($_) foreach @files;
done_testing;
