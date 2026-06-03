use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Net/CIDR/Set.pm',
    'lib/Net/CIDR/Set/IPv4.pm',
    'lib/Net/CIDR/Set/IPv6.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/ipv6.t',
    't/is_cidr.t',
    't/misc.t',
    't/octal.t',
    't/operations.t',
    't/private.t',
    't/validation.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
