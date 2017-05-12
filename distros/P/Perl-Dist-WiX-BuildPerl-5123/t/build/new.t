#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::Perl::Dist 0.300;
use File::Spec::Functions qw(catdir);

#####################################################################
# Complete Generation Run

# Throw information on the testing module up.
diag("Testing with Test::Perl::Dist $Test::Perl::Dist::VERSION");

# Create the dist object
my $dist = Test::Perl::Dist->new_test_class_short(
	'new', '5123', 'Perl::Dist::WiX', catdir(qw(t build)),
	user_agent_cache  => 0,
);

# Check useragent method
my $ua = $dist->user_agent;
isa_ok( $ua, 'LWP::UserAgent' );

test_run_dist( $dist );

test_verify_files_short('new', catdir(qw(t build)));

test_cleanup('new');

done_testing(1);


