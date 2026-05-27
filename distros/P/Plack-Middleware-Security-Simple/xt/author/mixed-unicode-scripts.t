use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

my @files = (
    'lib/Plack/Middleware/Security/Common.pm',
    'lib/Plack/Middleware/Security/Simple.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-Hash-Match.t',
    't/10-arrayref.t',
    't/10-coderef.t',
    't/10-hashref.t',
    't/20-logging.t',
    't/30-handler.t',
    't/31-status.t',
    't/40-common.t',
    't/author-changes.t',
    't/author-vars.t'
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
