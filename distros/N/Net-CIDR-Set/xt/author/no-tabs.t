use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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
    't/private.t'
);

notabs_ok($_) foreach @files;
done_testing;
