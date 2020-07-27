use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Parallel/ForkManager/Segmented.pm',
    't/00-compile.t',
    't/avoid-callback-on-empty-input.t',
    't/system-test--process-batch.t',
    't/system-test--stream-cb.t',
    't/system-test-1.t'
);

notabs_ok($_) foreach @files;
done_testing;
