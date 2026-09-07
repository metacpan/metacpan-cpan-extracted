use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

my @files = (
    'lib/Plack/Middleware/Greylist.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-greylist.t',
    't/02-rate-codes.t',
    't/03-override.t',
    't/04-ip6.t',
    't/05-callback.t'
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
