#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use version; our $VERSION = qv('v0.0.5');
use Readonly;
use English qw(-no_match_vars);

# Ensure a recent version of Test::Pod
Readonly my $MIN_TP => 1.22;

## no critic (ProhibitStringyEval RequireCheckingReturnValueOfEval)
eval "use Test::Pod $MIN_TP";
## use critic

if ($EVAL_ERROR) {
    plan skip_all => "Test::Pod $MIN_TP required for testing POD";
}

all_pod_files_ok();
