use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Net/Statsd/Lite.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-socket.t',
    't/data/counter.dat',
    't/data/gauge.dat',
    't/data/histogram.dat',
    't/data/meter.dat',
    't/data/multiple.dat',
    't/data/secure_set.dat',
    't/data/set.dat',
    't/data/timing.dat',
    't/lib/Net/Statsd/Lite/Dog.pm',
    't/lib/Net/Statsd/Lite/Test.pm'
);

notabs_ok($_) foreach @files;
done_testing;
