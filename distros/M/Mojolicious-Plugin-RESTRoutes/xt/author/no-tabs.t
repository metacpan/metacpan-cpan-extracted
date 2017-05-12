use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Mojolicious/Plugin/RESTRoutes.pm',
    't/10_basic.t'
);

notabs_ok($_) foreach @files;
done_testing;
