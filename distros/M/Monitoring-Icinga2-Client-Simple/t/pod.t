#!perl -T
use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Test::More;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;

## no critic(Lax::ProhibitStringyEval::ExceptForRequire, BuiltinFunctions::ProhibitStringyEval)
eval "use Test::Pod $min_tp; 1" // plan skip_all => "Test::Pod $min_tp required for testing POD";
all_pod_files_ok();
