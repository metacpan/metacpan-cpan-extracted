#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use version; our $VERSION = qv('v0.0.5');
use Readonly;
use English qw(-no_match_vars);

if ( !$ENV{RELEASE_TESTING} ) {
    plan( skip_all => 'Author tests not required for installation' );
}

Readonly my $MIN_TCM => 0.9;

## no critic (ProhibitStringyEval RequireCheckingReturnValueOfEval)
eval "use Test::CheckManifest $MIN_TCM";
## use critic

if ($EVAL_ERROR) {
    plan skip_all => "Test::CheckManifest $MIN_TCM required";
}

ok_manifest();
