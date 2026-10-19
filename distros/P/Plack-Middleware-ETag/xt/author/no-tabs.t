use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Plack/Middleware/ETag.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/00_compile.t',
    't/01_basic.t',
    't/02_last_modified.t'
);

notabs_ok($_) foreach @files;
done_testing;
