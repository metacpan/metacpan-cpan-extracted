use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Term/Shell.pm',
    't/00-compile.t',
    't/01require.t',
    't/02default.t',
    't/03catchsmry.t',
    't/cpan-changes.t',
    't/pod.t',
    't/style-trailing-space.t'
);

notabs_ok($_) foreach @files;
done_testing;
