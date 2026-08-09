#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

unless ($ENV{RELEASE_TESTING}) {
    plan skip_all => 'Author test; set RELEASE_TESTING to run';
}

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required" if $@;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required" if $@;

# Every public method is an XSUB with POD in the corresponding .pm.
# dl_load_flags is XSLoader plumbing, not API.
all_pod_coverage_ok({ also_private => [qr/^(dl_load_flags|bootstrap)$/] });
