use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

my @files = (
    'lib/Mojolicious/Plugin/Statsd.pm',
    'lib/Mojolicious/Plugin/Statsd/Adapter/Memory.pm',
    'lib/Mojolicious/Plugin/Statsd/Adapter/Statsd.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-basic.t',
    't/20-adapter-memory.t',
    't/25-adapter-statsd.t',
    't/40-statsd.t'
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
