#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use version; our $VERSION = qv('v0.0.5');
use Readonly;
use English qw(-no_match_vars);

# Ensure a recent version of Test::Pod::Coverage
Readonly my $MIN_TPC => 1.08;

## no critic (ProhibitStringyEval RequireCheckingReturnValueOfEval)
eval "use Test::Pod::Coverage $MIN_TPC";
## use critic

if ($EVAL_ERROR) {
    plan skip_all =>
      "Test::Pod::Coverage $MIN_TPC required for testing POD coverage";
}

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
Readonly my $MIC_PC => 0.18;

## no critic (ProhibitStringyEval RequireCheckingReturnValueOfEval)
eval "use Pod::Coverage $MIC_PC";
## use critic

if ($EVAL_ERROR) {
    plan skip_all => "Pod::Coverage $MIC_PC required for testing POD coverage";
}

all_pod_coverage_ok();
