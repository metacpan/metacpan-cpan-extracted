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
my $dist = Test::Perl::Dist->new_test_class_medium(
	'medium', '5123', 'Perl::Dist::WiX', catdir(qw(t build)),
	msi => 0,       # Can't have msi => 1 on a medium.
	zip => 1,
	user_agent_cache => 0,
	gcc_version      => 4,
);

test_run_dist( $dist );

test_verify_files_medium('medium', '512', catdir(qw(t build)));

test_cleanup('medium');

done_testing();