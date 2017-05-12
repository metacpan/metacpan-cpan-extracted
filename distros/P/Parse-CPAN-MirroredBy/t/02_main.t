#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use Parse::CPAN::MirroredBy;

# Locate the test file
my $file = catfile( 't', 'data', 'MIRRORED.BY' );
ok( -f $file, 'Found test file' );





#####################################################################
# Basic parsing

SCOPE: {
	# Default parser
	my $parser = Parse::CPAN::MirroredBy->new;
	isa_ok( $parser, 'Parse::CPAN::MirroredBy' );

	# Parse and check results
	my @mirrors = $parser->parse_file( $file );
	1;
}
