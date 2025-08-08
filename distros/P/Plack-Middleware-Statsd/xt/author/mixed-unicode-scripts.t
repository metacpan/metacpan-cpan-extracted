use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.1.5.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

my @files = (
    'lib/Plack/Middleware/Statsd.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-mock-statsd.t',
    't/02-logging.t',
    't/03-warnings.t',
    't/04-fatal.t',
    't/05-fatal.t',
    't/lib/MockStatsd.pm'
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
