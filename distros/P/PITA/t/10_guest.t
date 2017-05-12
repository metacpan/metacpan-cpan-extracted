#!/usr/bin/perl

# Testing PITA::Guest

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 47;

use PITA         ();
use File::Remove ();
use File::Spec::Functions ':ALL';

sub compare_guests {
	my ($left, $right, $message) = @_;
	delete $left->driver->{injector_dir};
	delete $left->driver->{workarea};
	delete $right->driver->{injector_dir};
	delete $right->driver->{workarea};
	is_deeply( $left, $right, $message );		
}

# Find the test guest file
my $local_empty = catfile( 't', 'guests', 'local_empty.pita' );
ok( -f $local_empty, 'Found local_empty test file' );

# Set up the write test guest file
my $local_write = rel2abs(catfile( 't', 'guests', 'local_write.pita' ));
File::Remove::clear($local_write);
ok( ! -f $local_write, 'local_write.pita does not exist' );

# Find the test request file
my $simple_request = catfile( 't', 'requests', 'simple_request.pita' );
ok( -f $simple_request, 'Found simple request file' );
my $simple_module = catfile( 't', 'requests', 'PITA-Test-Dummy-Perl5-Make-1.01.tar.gz' );
ok( -f $simple_module, 'Found simple dist file' );





#####################################################################
# Tests for the Local case that is not discovered

# Load the raw PITA::XML::Guest directly
SCOPE: {
	my $xml = PITA::XML::Guest->read( $local_empty );
	isa_ok( $xml, 'PITA::XML::Guest' );
	is( $xml->driver, 'Local', '->driver is Local' );
	is( scalar($xml->platforms),    0,  '->platforms(scalar) returns 0' );
	is_deeply( [ $xml->platforms ], [], '->platforms(list) return ()'   );

	# Write the file for the write test
	ok( $xml->write( $local_write ), '->write returns true' );
	my $xml2 = PITA::XML::Guest->read( $local_write );
	isa_ok( $xml2, 'PITA::XML::Guest' );
	is_deeply( $xml2, $xml, 'local_empty matches local_write' );
}

# Load a PITA::Guest for the local_empty case
my ($injector, $workarea);
SCOPE: {
	my $guest = PITA::Guest->new( $local_empty );
	isa_ok( $guest, 'PITA::Guest' );
	is( $guest->file, $local_empty,
		'->file returns the original filename' );
	isa_ok( $guest->guestxml,  'PITA::XML::Guest'           );
	is( $guest->discovered, '', '->discovered returns false' );
	isa_ok( $guest->driver, 'PITA::Guest::Driver'        );
	isa_ok( $guest->driver, 'PITA::Guest::Driver::Local' );
	is( scalar($guest->guestxml->platforms),    0,  '->platforms(scalar) returns 0' );
	is_deeply( [ $guest->guestxml->platforms ], [], '->platforms(list) return ()'   ); 

	# The needed directories are created
	$injector = $guest->driver->injector_dir;
	$workarea = $guest->driver->workarea;
	ok( $injector, 'Got an injector directory' );
	ok( $workarea, 'Got a workarea directory'  );
	ok( -d $injector, 'Injector directory created' );
	ok( -d $workarea, 'Workarea directory created' );

	# Ping the Guest
	ok( $guest->ping, '->ping returned true' );

	# Discover the platforms
	ok( $guest->discover, '->discover returned true' );
	is( scalar($guest->guestxml->platforms),    1,  '->platforms(scalar) returns 1' );
	isa_ok( ($guest->guestxml->platforms)[0], 'PITA::XML::Platform' );
}

# Are the directories removed on destruction
sleep 1;
ok( ! -d $injector, 'Injector directory is cleaned up' );
ok( ! -d $workarea, 'Workarea directory is cleaned up' );

# Repeat, but this time discover and save it
SCOPE: {
	my $guest = PITA::Guest->new( $local_write );
	isa_ok( $guest, 'PITA::Guest' );
	is( $guest->discovered, '', '->discovered is false' );
	ok( $guest->discover, '->discover returns true' );
	is( scalar($guest->guestxml->platforms), 1, '->platforms(scalar) returns 1' );
	isa_ok( ($guest->guestxml->platforms)[0], 'PITA::XML::Platform' );
	ok( $guest->save, '->save returns true' );

	# Did we save ok?
	my $guest2 = PITA::Guest->new( $local_write );
	isa_ok( $guest2, 'PITA::Guest' );
	compare_guests( $guest2, $guest, 'PITA::Guest object saved ok' );
}

# Execute a simple test run
SCOPE: {
	my $guest = PITA::Guest->new( $local_write );
	isa_ok( $guest,           'PITA::Guest'      );
	isa_ok( $guest->guestxml, 'PITA::XML::Guest' );

	# Load the request object
	my $request = PITA::XML::Request->read( $simple_request );
	isa_ok( $request, 'PITA::XML::Request' );
	is( $request->id, 'D7F50D84-7618-11DE-BE94-5E75E19EDF37', '->id ok' );

	# Try to test it
	my $report = $guest->test( $simple_request );
	isa_ok( $report, 'PITA::XML::Report' );

	# Check that it actually did a test
	is( scalar($report->installs), 1, '->installs returns 1 object' );
	my $install = ($report->installs)[0];
	isa_ok( $install, 'PITA::XML::Install' );
	isa_ok( $install->request, 'PITA::XML::Request' );
	is_deeply( $install->request, $request, 'Request matched original' );
	is( scalar($install->commands), 3, 'Found three commands' );
}
