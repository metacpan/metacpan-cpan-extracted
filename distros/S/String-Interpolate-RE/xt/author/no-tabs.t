use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/String/Interpolate/RE.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/bad_opts.t',
    't/format.t',
    't/generate.t',
    't/interp.t',
    't/package.t',
    't/recurse.t',
    't/variable_re.t'
);

notabs_ok($_) foreach @files;
done_testing;
