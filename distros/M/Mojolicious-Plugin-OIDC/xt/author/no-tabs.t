use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Mojolicious/Plugin/OIDC.pm',
    't/00-compile.t',
    't/auth-code-flow-IT.t',
    't/resource-server-IT.t'
);

notabs_ok($_) foreach @files;
done_testing;
