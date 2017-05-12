#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use File::Spec::Functions ':ALL';
use File::Remove 'clear';
use POE::Declare::Log::File ();

# Identify the test files
my $file1 = catfile( 't', '02_new.1' );
my $file2 = catfile( 't', '02_new.2' );
clear($file1, $file2);
ok( ! -f $file1, "Test file $file1 does not exist" );
ok( ! -f $file2, "Test file $file2 does not exist" );

# Non-lazy log file
my $log1 = POE::Declare::Log::File->new(
	Filename => $file1,
);
isa_ok( $log1, 'POE::Declare::Log::File' );
ok( -f $file1, 'Log file object without Lazy opens file immediately' );

# Lazy log file
my $log2 = POE::Declare::Log::File->new(
	Filename => $file2,
	Lazy     => 1,
);
isa_ok( $log2, 'POE::Declare::Log::File' );
ok( ! -f $file2, 'Log file object with Lazy does not open file' );
