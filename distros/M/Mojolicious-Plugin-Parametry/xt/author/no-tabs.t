use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Mojolicious/Plugin/Parametry.pm',
    'lib/Mojolicious/Plugin/Parametry/Paramer.pm',
    'lib/Mojolicious/Plugin/Parametry/ParamerHelpers.pm',
    't/00-basics.t',
    't/00-compile.t'
);

notabs_ok($_) foreach @files;
done_testing;
