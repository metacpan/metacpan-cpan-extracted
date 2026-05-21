use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Net/Statsd/Tiny.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/data/counter.dat',
    't/data/gauge.dat',
    't/data/histogram.dat',
    't/data/meter.dat',
    't/data/multiple.dat',
    't/data/set.dat',
    't/data/timing.dat',
    't/lib/Net/Statsd/Tiny/Test.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
