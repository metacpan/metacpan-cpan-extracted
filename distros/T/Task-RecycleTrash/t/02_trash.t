#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use File::Spec::Functions ':ALL';
use File::Remove 'trash';

my $file = catfile( 't', 'testfile' );
File::Remove::remove( $file );
ok( ! -f $file, 'File does not exist' );
END {
	File::Remove::remove( $file );
}

SKIP: {
	unless ( $^O eq 'darwin' or $^O eq 'MSWin32' ) {
		skip("Trash support not implemented", 2);
	}

	# Create a file and send it to the trash
	open( FILE, ">$file" ) or die "open: $!";
	print FILE "This is a test file\n" or die "print: $!";
	close( FILE ) or die "close: $!";
	ok( -f $file, 'Created test file' );

	# Move the file to the trash/recycle-bin
	File::Remove::trash( $file );

	# File should now be gone
	ok( ! -f $file, 'File was deleted successfully' );
}
