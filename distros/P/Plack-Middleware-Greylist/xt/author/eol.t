use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Plack/Middleware/Greylist.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-greylist.t',
    't/02-rate-codes.t',
    't/03-override.t',
    't/04-ip6.t',
    't/05-callback.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
