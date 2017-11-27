use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/parse-syslog-line.pl',
    'lib/Parse/Syslog/Line.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-parse.t',
    't/02-functions.t',
    't/03-datetime-calculations.t'
);

notabs_ok($_) foreach @files;
done_testing;
