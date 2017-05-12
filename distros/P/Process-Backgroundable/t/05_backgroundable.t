#!/usr/bin/perl

# Tests for Process::Backgroundable

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use File::Spec::Functions ':ALL';
use lib catdir('t', 'lib');

BEGIN {
	my $testdir = catdir('t', 'lib');
	ok( -d $testdir, 'Found test modules directory' );
	lib->import( $testdir );
}





#####################################################################
# Test Process::Backgroundable

# Create the test file
use File::Remove ();
my $background = catfile('t', 'background_file.txt');
File::Remove::clear($background);
open( FILE, '>', $background ) or die "Failed to open test file to write";
print FILE "Test content\n";
close FILE;

use MyBackgroundProcess ();
SCOPE: {
	# Create the file-removal backgrounded process
	my $remover = MyBackgroundProcess->new( file => $background );
	isa_ok( $remover, 'MyBackgroundProcess'     );
	isa_ok( $remover, 'Process'                 );
	isa_ok( $remover, 'Process::Backgroundable' ); 
	can_ok( $remover, 'background'              );

	# Trigger the backgrounding
	SCOPE: {
		local @Process::Backgroundable::PERLCMD = (
			@Process::Backgroundable::PERLCMD,
			'-I' . catdir('blib', 'lib'),
			'-I' . catdir('t',    'lib'),
			);
		ok( $remover->background, '->background returns ok' );
	}

	# The remove will wait 1 second.
	# Check that the file still exists, and thus the
	# background call didn't block.
	ok( -f $background, 'Test file still exists after ->background call' );

	# Wait 3 seconds to allow for startup and run time
	sleep 3;

	# Check the file is gone now
	ok( ! -f $background, 'Test file is removed correctly' );
}
