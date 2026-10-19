use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

my @files = (
    'lib/Plack/Middleware/ETag.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/00_compile.t',
    't/01_basic.t',
    't/02_last_modified.t'
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
