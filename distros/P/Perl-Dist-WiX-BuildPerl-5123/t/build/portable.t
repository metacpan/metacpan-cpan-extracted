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
	'portable', '5123', 'Perl::Dist::WiX', catdir(qw(t build)),
	portable => 1,
	user_agent_cache  => 0,
);

test_run_dist( $dist );

test_verify_files_long('portable', '512', catdir(qw(t build)));

test_verify_portability('portable', $dist->output_base_filename(), catdir(qw(t build)));

test_cleanup('portable');

done_testing();

