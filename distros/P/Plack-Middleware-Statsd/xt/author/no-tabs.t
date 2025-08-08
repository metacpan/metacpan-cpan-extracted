use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Plack/Middleware/Statsd.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-mock-statsd.t',
    't/02-logging.t',
    't/03-warnings.t',
    't/04-fatal.t',
    't/05-fatal.t',
    't/lib/MockStatsd.pm'
);

notabs_ok($_) foreach @files;
done_testing;
