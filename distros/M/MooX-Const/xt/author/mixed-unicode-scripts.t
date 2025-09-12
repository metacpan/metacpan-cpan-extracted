use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.3.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

my @files = (
    'lib/MooX/Const.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-has.t',
    't/20-moo.t',
    't/21-moox-typetiny.t',
    't/22-moo-coerce.t',
    't/23-moo-mungehas.t',
    't/30-strict.t',
    't/31-strict.t',
    't/40-moose.t',
    't/lib/MooTest.pm',
    't/lib/MooTest/MungeHas.pm',
    't/lib/MooTest/Strict.pm',
    't/lib/MooseTest.pm'
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
