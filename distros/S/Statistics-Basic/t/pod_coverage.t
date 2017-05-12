#!/usr/bin/perl -w

use strict;

unless( eval { require Test::More; 1} ) {
    print "1..0 # SKIP Author test.\n";
    exit 0;
}

Test::More->import();

no warnings;

# NOTE: please do not blame me for suggetions from this test.  Do not set
# TEST_AUTHOR and then tell me about it.  Use test at your own risk.
if ($ENV{TEST_AUTHOR} ne "author972" ) {
    plan( skip_all => 'Author test.' );
}

eval "use Test::Pod::Coverage 1.00";
plan( skip_all => "Test::Pod::Coverage 1.00 required for testing POD" ) if $@;


all_pod_coverage_ok();

#my @modules = grep { !m/ComputedVector/ } all_modules();
#pod_coverage_ok( $_ ) for @modules;
#my $trustme = { trustme => [qr/^(set_size|insert|append|ginsert|set_vector)$/] };
#pod_coverage_ok( "Statistics::Basic::ComputedVector", $trustme );
