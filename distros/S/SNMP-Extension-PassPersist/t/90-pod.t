#!perl -T
use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod
plan skip_all => "Test::Pod 1.22 required for testing POD"
    unless eval "use Test::Pod 1.22; 1";

all_pod_files_ok();

if (eval "use Pod::Checker; 1") {
    my $checker = Pod::Checker->new(-warnings => 1);
    $checker->parse_from_file($_, \*STDERR) for all_pod_files();
}

