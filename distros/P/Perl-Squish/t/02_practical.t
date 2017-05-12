#!/usr/bin/perl

# Compare a large number of specific constructs
# with the expected Lexer dumps.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

# Files to clean up
my @cleanup = ();
END {
	foreach ( @cleanup ) {
		unlink $_ if -e $_;
	}
}





#####################################################################
# Prepare

use Test::More tests => 17;
use File::Spec::Functions ':ALL';
use Perl::Squish;
use Scalar::Util 'refaddr';
use File::Copy;

my $testdir = catdir('t', 'data');

# Does the test directory exist?
ok( (-e $testdir and -d $testdir and -r $testdir), "Test directory $testdir found" );

# Find the .code test files
opendir( TESTDIR, $testdir ) or die "opendir: $!";
my @files = map { catfile( $testdir, $_ ) } sort grep { /\.pm$/ } readdir(TESTDIR);
closedir( TESTDIR ) or die "closedir: $!";
ok( scalar @files, 'Found at least one .pm file' );





#####################################################################
# Testing

foreach my $input ( @files ) {
	# Prepare
	my $output = "$input.squish";
	my $copy   = "$input.copy";
	my $copy2  = "$input.copy2";
	push @cleanup, $copy;
	#push @cleanup, $copy2;
	ok( copy( $input, $copy ), "Copied $input to $copy" );

	my $Original = new_ok( 'PPI::Document', [ $input  ] );
	my $Input    = new_ok( 'PPI::Document', [ $input  ] );
	my $Output   = new_ok( 'PPI::Document', [ $output ] );

	# Process the file
	my $rv = Perl::Squish->document( $Input );
	isa_ok( $rv, 'PPI::Document' );
	is( refaddr($rv), refaddr($Input), '->document returns original document' );
	is_deeply( $Input, $Output, 'Transform works as expected' );

	# Squish to another location
	ok( Perl::Squish->file( $copy, $copy2 ), '->file returned true' );
	my $Copy  = new_ok( 'PPI::Document', [ $copy  ] );
	is_deeply( $Copy, $Original, 'targeted transform leaves original unchanged' );
	my $Copy2 = new_ok( 'PPI::Document', [ $copy2 ] );
	is_deeply( $Copy2, $Output, 'targeted transform works as expected' );

	# Copy the file and process in-place
	ok( Perl::Squish->file( $copy ),
		'->file returned true' );
	$Copy = new_ok( 'PPI::Document', [ $copy ] );
	is_deeply( $Copy, $Output, 'In-place transform works as expected' );
}
