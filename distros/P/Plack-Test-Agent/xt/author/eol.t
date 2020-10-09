use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Plack/Test/Agent.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/2args.t',
    't/cookie.t',
    't/cycle.t',
    't/extra_get_args.t',
    't/hello.t',
    't/hello_server.t',
    't/mech.t',
    't/okay.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
