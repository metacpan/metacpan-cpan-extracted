use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Robots/Validate.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-config.t',
    't/10-basic.t',
    't/11-cache.t',
    't/12-shared-hostname.t',
    't/13-multiple-domains.t',
    't/14-ipv6.t',
    't/15-forward-lookup-limit.t',
    't/16-resolver-failure.t',
    't/17-empty-domains-config.t',
    't/20-basic-algorithm-ahocorasick.t',
    't/20-basic-toml-tiny.t',
    't/21-cache_failure-default.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
