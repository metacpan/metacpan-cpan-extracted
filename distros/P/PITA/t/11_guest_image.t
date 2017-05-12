#!/usr/bin/perl

# Testing PITA::Guest

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 109;

use PITA         ();
use File::Remove ();
use File::Spec::Functions ':ALL';

sub compare_guests {
	my ($left, $right, $message) = @_;
	delete $left->driver->{workarea};
	delete $left->driver->{injector_dir};
	delete $right->driver->{workarea};
	delete $right->driver->{injector_dir};
	is_deeply( $left, $right, $message );
}

# Find the test guest file
my $image_test = catfile( 't', 'guests', 'image_test.pita' );
ok( -f $image_test, 'Found image_test.pita test file' );

# Set up the write test guest file
my $image_write = rel2abs(catfile( 't', 'guests', 'image_write.pita' ));
File::Remove::clear($image_write);
ok( ! -f $image_write, 'local_write.pita does not exist' );

# Find the test request file
my $simple_request = catfile( 't', 'requests', 'simple_request.pita' );
ok( -f $simple_request, 'Found simple request file' );
my $simple_module = catfile( 't', 'requests', 'PITA-Test-Dummy-Perl5-Make-1.01.tar.gz' );
ok( -f $simple_module, 'Found simple dist file' );





#####################################################################
# Prepare a common Request object

# Load a request object
my $request = PITA::XML::Request->read( $simple_request );
isa_ok( $request, 'PITA::XML::Request' );
my $tarball = $request->find_file( $simple_request );
ok( $tarball, 'Found tarball for request' );
ok( -f $tarball, 'Confirm that tarball exists' );
unless ( file_name_is_absolute( $tarball ) ) {
	$tarball = rel2abs( $tarball );
}
ok( -f $tarball, 'Confirm that tarball exists (absolute)' );
$request->file->{filename} = $tarball;

# Override the request id
$request->{id} = 1234;
is( $request->id, 1234, 'Request id is 1234' );





#####################################################################
# Working with a PITA::XML::Guest

# Load the raw PITA::XML::Guest directly
SCOPE: {
	my $xml = PITA::XML::Guest->read($image_test);
	isa_ok( $xml, 'PITA::XML::Guest' );
	is( $xml->driver, 'Image::Test', '->driver is Local' );
	is( scalar($xml->platforms),    0,  '->platforms(scalar) returns 0' );
	is_deeply( [ $xml->platforms ], [], '->platforms(list) return ()'   );

	# Write the file for the write test
	ok( $xml->write($image_write), '->write returns true' );
	my $xml2 = PITA::XML::Guest->read($image_write);
	isa_ok( $xml2, 'PITA::XML::Guest' );
	is_deeply( $xml2, $xml, 'local_empty matches local_write' );
}





#####################################################################
# Preparation

# Load a PITA::Guest for the image_test case and test the various prepares
my @working_dirs = ();
SCOPE: {
	my $guest = PITA::Guest->new($image_test);
	isa_ok( $guest, 'PITA::Guest' );
	is( $guest->file, $image_test, '->file returns the original filename' );
	isa_ok( $guest->guestxml,  'PITA::XML::Guest'              );
	is( $guest->discovered, '', '->discovered returns false'   );
	isa_ok( $guest->driver, 'PITA::Guest::Driver'              );
	isa_ok( $guest->driver, 'PITA::Guest::Driver::Image'       );
	isa_ok( $guest->driver, 'PITA::Guest::Driver::Image::Test' );
	isa_ok( $guest->driver->support_server_new, 'PITA::Guest::Server::Process' );
	is( $guest->driver->support_server, undef, 'Not support server when not prepared' );
	is( scalar($guest->guestxml->platforms),    0,  '->platforms(scalar) returns 0' );
	is_deeply( [ $guest->guestxml->platforms ], [], '->platforms(list) return ()'   ); 

	# Check various working directories are created
	ok( -d $guest->driver->injector_dir, 'Driver injector directory is created' );

	# Save a copy for later
	@working_dirs = (
		$guest->driver->injector_dir,
	);

	# Check that we can prepare for a ping
	ok( $guest->driver->ping_prepare, '->driver->ping_prepare returns true' );
	isa_ok( $guest->driver->support_server, 'PITA::Guest::Server::Process' );
	my $injector = $guest->driver->injector_dir;
	ok( -d $injector, 'Injector exists' );
	ok( -f catfile( $injector, 'image.conf' ), 'image.conf file created' );
	ok( ! -d catfile( $injector, 'perl5lib' ), 'perl5lib dir not created' );
	ok( opendir( INJECTOR, $injector ), 'Opened injector for reading' );
	ok( scalar(no_upwards(readdir(INJECTOR))), 'Injector contains files' );
	ok( closedir( INJECTOR ), 'Closed injector' );

	# Flush the injector
	ok( $guest->driver->clean_injector, 'Cleaned injector' );
	ok( opendir( INJECTOR, $injector ), 'Opened injector for reading' );
	is( scalar(no_upwards(readdir(INJECTOR))), 0, 'Cleaned injector ok' );
	ok( closedir( INJECTOR ), 'Closed injector' );

	# Check that we can prepare for discovery
	ok( $guest->driver->discover_prepare, '->driver->discover_prepare returns true' );
	isa_ok( $guest->driver->support_server, 'PITA::Guest::Server::Process' );
	ok( -d $injector, 'Injector exists' );
	ok( -f catfile( $injector, 'image.conf' ), 'image.conf file created' );
	ok( -d catfile( $injector, 'perl5lib' ),   'perl5lib dir not created' );
	ok( -f catfile( $injector, 'perl5lib', 'PITA', 'Scheme.pm' ), 'PITA::Scheme found in perl5lib' );
	ok( opendir( INJECTOR, $injector ), 'Opened injector for reading' );
	ok( scalar(no_upwards(readdir(INJECTOR))), 'Injector contains files' );
	ok( closedir( INJECTOR ), 'Closed injector' );

	# Flush the injector
	ok( $guest->driver->clean_injector, 'Cleaned injector' );
	ok( opendir( INJECTOR, $injector ), 'Opened injector for reading' );
	is( scalar(no_upwards(readdir(INJECTOR))), 0, 'Cleaned injector ok' );
	ok( closedir( INJECTOR ), 'Closed injector' );

	# Check that we can prepare for a test
	ok( $guest->driver->test_prepare($request), '->driver->test_prepare returns true' );
	isa_ok( $guest->driver->support_server, 'PITA::Guest::Server::Process' );
	ok( -d $injector, 'Injector exists' );
	ok( -f catfile( $injector, 'image.conf' ), 'image.conf file created' );
	ok( -d catfile( $injector, 'perl5lib' ),   'perl5lib dir created' );
	ok( -f catfile( $injector, 'perl5lib', 'PITA', 'Scheme.pm' ), 'PITA::Scheme found in perl5lib' );
	ok( -f catfile( $injector, 'request-1234.pita' ), 'request-1234.pita file created' );
	ok( opendir( INJECTOR, $injector ), 'Opened injector for reading' );
	ok( scalar(no_upwards(readdir(INJECTOR))), 'Injector contains files' );
	ok( closedir( INJECTOR ), 'Closed injector' );

	# Flush the injector
	ok( $guest->driver->clean_injector, 'Cleaned injector' );
	ok( opendir( INJECTOR, $injector ), 'Opened injector for reading' );
	is( scalar(no_upwards(readdir(INJECTOR))), 0, 'Cleaned injector ok' );
	ok( closedir( INJECTOR ), 'Closed injector' );
}

sleep 1;

# Check all the various work directories are removed
ok( ! -d $working_dirs[0], 'Driver injector removed' );





#####################################################################
# Test the ping method

SCOPE: {
	my $guest = PITA::Guest->new($image_test);
	isa_ok( $guest, 'PITA::Guest' );

	# Ping the guest
	ok( $guest->ping, '->ping returns ok' );
	is( $guest->driver->support_server, undef, 'Support Server cleaned up' );
	my $last_server = $PITA::Guest::Driver::Image::Test::LAST_SUPPORT_SERVER;
	is( $last_server->pinged, 1, '->pinged ok' );
	is_deeply( $last_server->mirrored, [ ], '->mirrored ok' );
	is_deeply( $last_server->uploaded, [ ], '->uploaded ok' );
	$PITA::Guest::Driver::Image::Test::LAST_SUPPORT_SERVER = undef;
}





#####################################################################
# Test the discover method

SCOPE: {
	my $guest = PITA::Guest->new( $image_test );
	isa_ok( $guest, 'PITA::Guest' );
	ok( $guest->driver->snapshot, 'Guest running in snapshot mode' );
	is( $guest->discovered, '', '->discovered is false' );

	# Discover the platforms
	ok( $guest->discover, '->discover returns ok' );
	is( $guest->driver->support_server, undef, 'Support Server cleaned up' );
	my $last_server = $PITA::Guest::Driver::Image::Test::LAST_SUPPORT_SERVER;
	is( $last_server->pinged, 1, '->pinged ok' );
	is_deeply( $last_server->mirrored, [ ], '->mirrored ok' );
	my $uploaded = $last_server->uploaded;
	is( ref($uploaded), 'ARRAY', '->uploaded ok' );
	is( scalar(@$uploaded), 1, '1 file uploaded' );
	is( $uploaded->[0]->[0], '/1', 'Uploaded /1' );
	$PITA::Guest::Driver::Image::Test::LAST_SUPPORT_SERVER = undef;

	# Is the guest now discovered?
	is( $guest->discovered, 1, '->discovered returns true' );
}

# Again, but with write-back
SCOPE: {
	# Rebuild the write file
	my $xml = PITA::XML::Guest->read($image_test);
	isa_ok( $xml, 'PITA::XML::Guest' );
	ok( $xml->write($image_write), '->write returns true' );

	# Load it
	my $guest = PITA::Guest->new( $image_write );
	isa_ok( $guest, 'PITA::Guest' );

	# Discover it
	is( $guest->discovered, '', '->discovered is false' );
	ok( $guest->discover, '->discover returns ok' );
	is( $guest->discovered, 1, '->discovered returns true' );

	# Save it
	ok( $guest->save, '->save returns true' );
	is( $guest->driver->support_server, undef, 'Support Server cleaned up' );
	my $last_server = $PITA::Guest::Driver::Image::Test::LAST_SUPPORT_SERVER;
	is( $last_server->pinged, 1, '->pinged ok' );
	is_deeply( $last_server->mirrored, [ ], '->mirrored ok' );
	my $uploaded = $last_server->uploaded;
	is( ref($uploaded), 'ARRAY', '->uploaded ok' );
	is( scalar(@$uploaded), 1, '1 file uploaded' );
	is( $uploaded->[0]->[0], '/1', 'Uploaded /1' );
	$PITA::Guest::Driver::Image::Test::LAST_SUPPORT_SERVER = undef;

	# Load it again
	my $guest2 = PITA::Guest->new( $image_write );
	isa_ok( $guest, 'PITA::Guest' );
	is( $guest->discovered, 1, 'Saved and reloaded guest remains discovered' );
}





#####################################################################
# Test the test method

SCOPE: {
	# Load the pre-discovered config
	my $guest = PITA::Guest->new( $image_write );
	isa_ok( $guest, 'PITA::Guest' );
	is( $guest->discovered, 1, '->discovered is true' );

	# Run the test
	my $report = $guest->test( $simple_request );
	isa_ok( $report, 'PITA::XML::Report' );

	# Check results
	is( $guest->driver->support_server, undef, 'Support Server cleaned up' );
	my $last_server = $PITA::Guest::Driver::Image::Test::LAST_SUPPORT_SERVER;
	is( $last_server->pinged, 1, '->pinged ok' );
	is_deeply( $last_server->mirrored, [ ], '->mirrored ok' );
	my $uploaded = $last_server->uploaded;
	is( ref($uploaded), 'ARRAY', '->uploaded ok' );
	is( scalar(@$uploaded), 1, '1 file uploaded' );
	is(
		$uploaded->[0]->[0],
		'/D7F50D84-7618-11DE-BE94-5E75E19EDF37',
		'Uploaded /D7F50D84-7618-11DE-BE94-5E75E19EDF37',
	);
	$PITA::Guest::Driver::Image::Test::LAST_SUPPORT_SERVER = undef;
}
