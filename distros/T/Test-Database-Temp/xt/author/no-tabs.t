use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test/Database/Temp.pm',
    't/test-all-databases.t'
);

notabs_ok($_) foreach @files;
done_testing;
