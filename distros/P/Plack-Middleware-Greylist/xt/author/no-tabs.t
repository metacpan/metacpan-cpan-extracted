use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Plack/Middleware/Greylist.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-greylist.t',
    't/02-rate-codes.t',
    't/03-override.t',
    't/04-ip6.t',
    't/05-callback.t'
);

notabs_ok($_) foreach @files;
done_testing;
