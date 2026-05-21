use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Plack/Middleware/Text/Minify.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-path-callback.t',
    't/02-path-regex.t',
    't/03-type-callback.t',
    't/03-type-regex.t',
    't/04-empty.t',
    't/05-psgi-no-minify.t',
    't/06-handle.t'
);

notabs_ok($_) foreach @files;
done_testing;
