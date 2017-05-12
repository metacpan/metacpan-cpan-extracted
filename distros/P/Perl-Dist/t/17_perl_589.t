#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use LWP::Online ':skip_all';
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	};
	unless ( $ENV{RELEASE_TESTING} ) {
		plan( skip_all => 'No RELEASE_TESTING: Skipping very long test' );
		exit(0);
	}
	plan( tests => 13 );
}

use File::Spec::Functions ':ALL';
use t::lib::Test;





#####################################################################
# Complete Generation Run

# Create the dist object
my $dist = t::lib::Test->new5(17);
isa_ok( $dist, 't::lib::Test5' );

# Run the dist object, and ensure everything we expect was created
diag( "Building test dist, may take up to an hour... (sorry)" );
ok( $dist->run, '->run ok' );

# C toolchain files
ok(
	-f catfile( qw{ t tmp17 image c bin dmake.exe } ),
	'Found dmake.exe',
);
ok(
	-f catfile( qw{ t tmp17 image c bin startup Makefile.in } ),
	'Found startup',
);
ok(
	-f catfile( qw{ t tmp17 image c bin pexports.exe } ),
	'Found pexports',
);

# Perl core files
ok(
	-f catfile( qw{ t tmp17 image perl bin perl.exe } ),
	'Found perl.exe',
);

# Toolchain files
ok(
	-f catfile( qw{ t tmp17 image perl site lib LWP.pm } ),
	'Found LWP.pm',
);

# Custom installed file
ok(
	-f catfile( qw{ t tmp17 image perl site lib Config Tiny.pm } ),
	'Found Config::Tiny',
);

# Did we build 5.8.9?
ok(
	-f catfile( qw{ t tmp17 image perl bin perl58.dll } ),
	'Found Perl 5.8.9 DLL',
);
