use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MooX/Lsub.pm',
    't/00-compile/lib_MooX_Lsub_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic-moo.t',
    't/02-basic-moose.t',
    't/03-basic-moose-immute.t',
    't/04-clean-ns-moose.t',
    't/04-clean-ns.t',
    't/05-autoclean-ns-moose.t',
    't/05-autoclean-ns.t',
    't/06-expected-fails.t',
    't/07-internals-source.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
