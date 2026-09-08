use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

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

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
