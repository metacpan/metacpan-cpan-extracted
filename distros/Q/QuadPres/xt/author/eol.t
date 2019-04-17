use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
