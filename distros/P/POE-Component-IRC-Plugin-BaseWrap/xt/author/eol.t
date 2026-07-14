use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/POE/Component/IRC/Plugin/BasePoCoWrap.pm',
    'lib/POE/Component/IRC/Plugin/BaseWrap.pm',
    't/00-basepocowrap-load.t',
    't/00-basewrap-load.t',
    't/00-compile.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
