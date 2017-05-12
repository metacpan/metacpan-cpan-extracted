#!/usr/bin/perl -w

# Tests for Process::YAML

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			'lib',
			);
	}
}

use lib catdir('t', 'lib');
use Test::More tests => 33;
use File::Remove 'remove';

BEGIN {
	my $testdir = catdir('t', 'lib');
	ok( -d $testdir, 'Found test modules directory' );
	lib->import( $testdir );
}

# Check the two files we'll need
my $filename   = catfile( 't', '02filename.dat'   );
my $filehandle = catfile( 't', '02filehandle.dat' );
      remove($filename)   if -f $filename;
      remove($filehandle) if -f $filehandle;
END { remove($filename)   if -f $filename;   }
END { remove($filehandle) if -f $filehandle; }




#####################################################################
# Write out to all three types of handle

# Write to everything we support
use MyYAMLProcess ();
SCOPE: {
	local $/ = undef;

	# Create the test object
	my $object = MyYAMLProcess->new( foo => 'bar' );
	isa_ok( $object, 'Process'               );
	isa_ok( $object, 'Process::Serializable' );
	isa_ok( $object, 'Process::YAML'         );
	isa_ok( $object, 'MyYAMLProcess'         );

	# A normal string
	my $string = '';
	ok( $object->serialize( \$string ), '->serialize(string) returns ok' );

	# A file name
	ok( $object->serialize( $filename ), '->serialize(filename) returns ok' );
	ok( -f $filename, '->serialize(filename) created a file' );
	ok( open( FILE, '<', $filename ), 'Opened file to read it back in' );
	my $file = <FILE>;
	ok( $file, 'Read file back in'  );
	ok( close(FILE), 'Closed file' );

	# A file handle
	ok( open( HANDLE, '>', $filehandle ), 'Opened filehandle' );
	ok( $object->serialize( \*HANDLE ), '->serialize(filehandle) returns ok' );
	ok( close( HANDLE ), 'Closed filehandle' );
	ok( open( HANDLE, '<', $filehandle ), 'Opened filehandle up again' );
	my $fhstring = <HANDLE>;
	ok( $fhstring, 'Read handle back in' );
	ok( close(HANDLE), 'Closed handle' );

	# An io handle
	my $string2 = '';
	my $iohandle  = IO::String->new( \$string2 );
	isa_ok( $iohandle, 'IO::String' );
	isa_ok( $iohandle, 'IO::Handle' );
	ok( $object->serialize( $iohandle ), '->serialize(iohandle) returns ok' );

	# Do they all match
	is( $string, $file,     'serialize(string) matches serialize(filename)'   );
	is( $string, $fhstring, 'serialize(string) matches serialize(filehandle)' );
	is( $string, $string2,  'serialize(string) matches serialize(iohandle)'   );

	# Now deserialize from the various things
	ok( open( HANDLE, '<', $filehandle ), 'Opened filehandle' );
	ok( $iohandle->seek(0,0), 'Seeked to (0,0)' );
	my $thawed1 = MyYAMLProcess->deserialize( \$string  );
	my $thawed2 = MyYAMLProcess->deserialize( $filename );
	my $thawed3 = MyYAMLProcess->deserialize( \*HANDLE  );
	my $thawed4 = MyYAMLProcess->deserialize( $iohandle );
	isa_ok( $thawed1, 'MyYAMLProcess' );
	isa_ok( $thawed2, 'MyYAMLProcess' );
	isa_ok( $thawed3, 'MyYAMLProcess' );
	isa_ok( $thawed4, 'MyYAMLProcess' );

	# Do they all match the original
	is_deeply( $object, $thawed1, 'object matches deserialize(string)'     );
	is_deeply( $object, $thawed2, 'object matches deserialize(filename)'   );
	is_deeply( $object, $thawed3, 'object matches deserialize(filehandle)' );
	is_deeply( $object, $thawed4, 'object matches deserialize(iohandle)'   );

	# Clean up
	close( HANDLE );
}

1;
