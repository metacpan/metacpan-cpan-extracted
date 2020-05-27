use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/OpenOffice/OODoc/HeadingStyles.pm',
    't/00-compile.t',
    't/00_use_ok.t',
    't/10_createHeadingStyle.t',
    't/11_establishHeadingStyle.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
