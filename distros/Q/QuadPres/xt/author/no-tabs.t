use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/QuadPres.pm',
    'lib/QuadPres/Base.pm',
    'lib/QuadPres/Config.pm',
    'lib/QuadPres/Exception.pm',
    'lib/QuadPres/FS.pm',
    'lib/QuadPres/Url.pm',
    'lib/QuadPres/VimIface.pm',
    'lib/QuadPres/WriteContents.pm',
    't/00-compile.t'
);

notabs_ok($_) foreach @files;
done_testing;
