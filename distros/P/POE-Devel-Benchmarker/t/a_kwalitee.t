#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	eval "require Test::Kwalitee";
	if ( $@ ) {
		plan skip_all => 'Test::Kwalitee required for measuring the kwalitee';
	} else {
		Test::Kwalitee->import();

		# That piece of crap dumps files all over :(
		cleanup_debian_files();
	}
}

# Module::CPANTS::Kwalitee::Distros suck!
#t/a_manifest..............1/1
##   Failed test at t/a_manifest.t line 13.
##          got: 1
##     expected: 0
## The following files are not named in the MANIFEST file: /home/apoc/workspace/VCS-perl-trunk/VCS-2.12.2/Debian_CPANTS.txt
## Looks like you failed 1 test of 1.
#t/a_manifest.............. Dubious, test returned 1 (wstat 256, 0x100)
sub cleanup_debian_files {
	foreach my $file ( qw( Debian_CPANTS.txt ../Debian_CPANTS.txt ) ) {
		if ( -e $file and -f _ ) {
			my $status = unlink( $file );
			if ( ! $status ) {
				warn "unable to unlink $file";
			}
		}
	}

	return;
}

