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
if ($ENV{TEST_AUTHOR} ne "author972") {
    plan( skip_all => 'Author test.' );
}

unless( eval { require Test::Perl::Critic; 1 } ) {
    plan( skip_all => 'Test::Perl::Critic required for test.');
}

Test::Perl::Critic->import();
all_critic_ok();
