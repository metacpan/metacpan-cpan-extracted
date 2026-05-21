use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

my @files = (
    'lib/Net/Statsd/Lite.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
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

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
