use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

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

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
