use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Schedule/Cron/Events.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01base.t',
    't/02errs.t',
    't/03-rt68393.t',
    't/04-rt53899.t',
    't/05-rt109246.t'
);

notabs_ok($_) foreach @files;
done_testing;
