package MyTest::Net::NSCA::Client::InitialPacket;

use strict;
use warnings 'all';

use Data::Section '-setup';
use MIME::Base64 2.00 ();
use Test::Fatal;
use Test::More 0.18;

use base 'MyTest::Class';

sub constructor_new : Tests(4) {
	my ($test) = @_;

	# Get the name of the class we are testing
	my $class = $test->class;

	# Make a HASH of arguments for constructor
	my %options = (
		unix_timestamp => 1_234_567,
	);

	# Make sure new exists
	can_ok $class, 'new';

	# Constructor with HASH
	my $packet = new_ok $class, [%options];

	# Constructor with HASHREF
	$packet = new_ok $class, [\%options];

	ok(exception { $class->new(bad_argument => 1) }, 'Constructor dies on non-existant attribute');

	return;
}

sub attribute_initialization_vector : Tests(3) {
	my ($test) = @_;

	# Get the name of the class we are testing
	my $class = $test->class;

	can_ok $class, 'initialization_vector';

	# Get a basic packet
	my $packet = $class->new;

	# Check built IV length
	is(length($packet->initialization_vector),
		$packet->server_config->initialization_vector_length,
		'Default iv is right length');

	# Packet with IV too short
	like(exception { $class->new(initialization_vector => 'IamBADiv') },
		qr{initialization_vector is not the correct size},
		'initialization_vector is not the correct size');

	return;
}

sub initial_packet_generation : Tests(9) {
	my ($test) = @_;

	# Get the name of the class we are testing
	my $class = $test->class;

	# Make a packet
	my $packet = $class->new;

	# Should stringify to the packet
	unlike "$packet", qr{$class}msx, 'Stringifies to packet';

	# Can we to_string?
	can_ok $class, 'to_string';

	# Stringify is the same as to_string
	is "$packet", $packet->to_string, 'Stringify uses to_string';

	# Decode the packet using the new constructor
	my $decoded_packet = new_ok $class, ["$packet"];

	# Make sure the decoding worked
	is $decoded_packet->initialization_vector, $packet->initialization_vector, 'initialization_vector decoded correctly';
	is $decoded_packet->unix_timestamp       , $packet->unix_timestamp       , 'unix_timestamp decoded correctly';

	# Random bad data fails
	ok(exception { $class->new('I am garbage') }, 'Garbage does not decode');

	# Decode packet and check
	$decoded_packet = $class->new($test->_packet);

	# Checking the list
	is $decoded_packet->initialization_vector,
		"\x1B\x04\x75\x77\xED\x09\x1F\x8A\x3C\xC2\x2C\xAC\xE7\x78\xAE\xB3".
		"\xF1\x24\x03\x89\x9C\x75\xE9\x41\x56\x54\x26\xBE\x48\x7C\xAA\x54".
		"\xDE\xFE\xF8\x3F\x87\x85\x94\xA1\x8F\x22\x7C\x1D\x49\x64\xDE\x5A".
		"\xB8\xA3\x27\x6D\x9C\x4D\xCB\x83\x51\x18\x07\x41\xD3\x87\xD2\xD7".
		"\xB8\x2F\xB9\x2F\x4F\x83\xDE\x05\x71\x96\x88\xA9\x13\xA7\x8A\x5E".
		"\x3A\x5F\x38\x95\x9C\x11\x0E\x17\xD9\x89\x57\x5B\x12\x0E\xF7\x39".
		"\xEA\x55\xFB\x56\xD9\x4D\xE6\xC5\xB7\x3C\x9D\x2E\x60\x0C\xA0\x96".
		"\xA0\xA4\x50\x25\x70\x5E\xAA\xD7\xAD\x03\x3C\xB0\x15\x5A\x0D\x2F",
		'initialization_vector decoded correctly';
	is $decoded_packet->unix_timestamp       , 1254605822         , 'unix_timestamp decoded correctly';
}

sub _get_base64_section {
	return MIME::Base64::decode(${__PACKAGE__->section_data($_[0])});
}
sub _packet { _get_base64_section('packet') }

1;

__DATA__
__[ packet ]__
GwR1d+0JH4o8wiys53ius/EkA4mcdelBVlQmvkh8qlTe/vg/h4WUoY8ifB1JZN5auKMnbZxNy4NR
GAdB04fS17gvuS9Pg94FcZaIqROnil46XziVnBEOF9mJV1sSDvc56lX7VtlN5sW3PJ0uYAyglqCk
UCVwXqrXrQM8sBVaDS9Kx8P+
