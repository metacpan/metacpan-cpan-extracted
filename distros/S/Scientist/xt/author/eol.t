use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Scientist.pm',
    'lib/Scientist.pod',
    't/00-compile.t',
    't/context.t',
    't/enabled.t',
    't/experiment_name.t',
    't/lib/Named/Scientist.pm',
    't/lib/Publishing/Scientist.pm',
    't/publish.t',
    't/random_order.t',
    't/regression/16.t',
    't/result.t',
    't/wantarray.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
