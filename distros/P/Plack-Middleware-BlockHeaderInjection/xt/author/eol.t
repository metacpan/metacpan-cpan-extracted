use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Plack/Middleware/BlockHeaderInjection.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-compile.t',
    't/10-basic.t',
    't/11-status.t',
    't/12-clean.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
