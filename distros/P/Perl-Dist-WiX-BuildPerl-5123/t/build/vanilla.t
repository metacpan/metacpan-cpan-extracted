#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::Perl::Dist 0.300;
use File::Spec::Functions qw(catdir);

plan( skip_all =>
	  'Skipping for now.' );

#####################################################################
# Complete Generation Run

# Create the dist object
my $dist = Test::Perl::Dist->new_test_class_long(
	'long', '5123', 'Perl::Dist::VanillaWiX', catdir(qw(t build)),
	user_agent_cache  => 0,
	gcc_version       => 4,
);

test_run_dist( $dist );

test_verify_files_long('long', '512', catdir(qw(t build)));

test_cleanup('long');

done_testing();
