use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Net/HTTP.pm',
    'lib/Net/HTTP/Methods.pm',
    'lib/Net/HTTP/NB.pm',
    'lib/Net/HTTPS.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/http-nb.t',
    't/http.t',
    't/live-https.t',
    't/live.t',
    't/socket-class.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
