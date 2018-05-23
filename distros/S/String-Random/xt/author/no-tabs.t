use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/String/Random.pm',
    't/00-compile.t',
    't/01_use.t',
    't/02_new.t',
    't/03_random_string.t',
    't/04_randpattern.t',
    't/05_randregex.t',
    't/06_random_regex.t',
    't/07_rand_gen.t'
);

notabs_ok($_) foreach @files;
done_testing;
