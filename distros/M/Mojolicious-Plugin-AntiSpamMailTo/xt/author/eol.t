use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Mojolicious/Plugin/AntiSpamMailTo.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-explicit-use.t',
    't/02-store-address.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
