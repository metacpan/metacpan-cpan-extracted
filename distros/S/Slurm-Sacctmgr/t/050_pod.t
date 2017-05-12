#!/usr/bin/env perl 
#
#Test that Slurm::Sacctmgr and Slurm::Sacctmgr::* pod documentation is
#valid.  This is only needed when making a distribution, not relevant
#to installing the module.
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 050_pod.t'
# You will also need to set the RELEASE_TESTING environmental variable in order
# to actual execute the test.

use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
