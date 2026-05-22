use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Mojolicious/Plugin/Statsd.pm',
    'lib/Mojolicious/Plugin/Statsd/Adapter/Memory.pm',
    'lib/Mojolicious/Plugin/Statsd/Adapter/Statsd.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-basic.t',
    't/20-adapter-memory.t',
    't/25-adapter-statsd.t',
    't/40-statsd.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
