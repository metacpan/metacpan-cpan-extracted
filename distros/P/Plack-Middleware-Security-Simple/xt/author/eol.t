use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Plack/Middleware/Security/Common.pm',
    'lib/Plack/Middleware/Security/Simple.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-Hash-Match.t',
    't/10-arrayref.t',
    't/10-coderef.t',
    't/10-hashref.t',
    't/20-logging.t',
    't/30-handler.t',
    't/31-status.t',
    't/40-common.t',
    't/author-changes.t',
    't/author-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
