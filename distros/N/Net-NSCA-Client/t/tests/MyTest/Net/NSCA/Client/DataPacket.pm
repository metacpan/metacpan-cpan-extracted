package MyTest::Net::NSCA::Client::DataPacket;

use strict;
use warnings 'all';

use Data::Section '-setup';
use MIME::Base64 2.00 ();
use Test::Fatal;
use Test::More 0.18;

use base 'MyTest::Class';

sub constructor_new : Tests(5) {
	my ($test) = @_;

	# Get the name of the class we are testing
	my $class = $test->class;

	# Make a HASH of arguments for constructor
	my %options = (
		hostname            => 'www.example.net',
		service_description => 'Apache',
		service_message     => 'OK - Apache running',
		service_status      => 0,
	);

	# Make sure new exists
	can_ok $class, 'new';

	# Constructor with HASH
	my $packet = new_ok $class, [%options];

	# Constructor with HASHREF
	$packet = new_ok $class, [\%options];

	ok(exception { $class->new }, 'Constructor dies with no options');
	ok(exception { $class->new(bad_argument => 1) }, 'Constructor dies on non-existant attribute');

	return;
}

sub data_packet_generation : Tests(no_plan) {
	my ($test) = @_;

	# Get the name of the class we are testing
	my $class = $test->class;

	# Make a HASH of arguments for constructor
	my %options = (
		hostname            => 'www.example.net',
		service_description => 'Apache',
		service_message     => 'OK - Apache running',
		service_status      => 0,
	);

	# Make a packet
	my $packet = $class->new(%options);

	# Should stringify to the packet
	unlike "$packet", qr{$class}msx, 'Stringifies to packet';

	# Can we to_string?
	can_ok $class, 'to_string';

	# Stringify is the same as to_string
	is "$packet", $packet->to_string, 'Stringify uses to_string';

	# Decode the packet using the new constructor
	my $decoded_packet = new_ok $class, ["$packet"];

	# Make sure the decoding worked
	is $decoded_packet->hostname           , $packet->hostname           , 'hostname decoded correctly';
	is $decoded_packet->packet_version     , $packet->packet_version     , 'packet_version decoded correctly';
	is $decoded_packet->service_description, $packet->service_description, 'service_description decoded correctly';
	is $decoded_packet->service_message    , $packet->service_message    , 'service_message decoded correctly';
	is $decoded_packet->service_status     , $packet->service_status     , 'service_status decoded correctly';
	is $decoded_packet->unix_timestamp     , $packet->unix_timestamp     , 'unix_timestamp decoded correctly';

	# Random bad data fails
	ok(exception { $class->new('I am garbage') }, 'Garbage does not decode');

	# Decode two packets which should be the same
	foreach my $packet_bytes ($test->_packet1, $test->_packet2) {
		$decoded_packet = $class->new($packet_bytes);

		# Checking the list
		is $decoded_packet->hostname           , 'www.example.com'  , 'hostname decoded correctly';
		is $decoded_packet->packet_version     , 3                  , 'packet_version decoded correctly';
		is $decoded_packet->service_description, 'Test'             , 'service_description decoded correctly';
		is $decoded_packet->service_message    , 'OK - Testing fine', 'service_message decoded correctly';
		is $decoded_packet->service_status     , 0                  , 'service_status decoded correctly';
		is $decoded_packet->unix_timestamp     , 1254600142         , 'unix_timestamp decoded correctly';
	}
}

sub _get_base64_section {
	return MIME::Base64::decode(${__PACKAGE__->section_data($_[0])});
}
sub _packet1 { _get_base64_section('packet_1') }
sub _packet2 { _get_base64_section('packet_2') }

1;

__DATA__
__[ packet_1 ]__
AAMAAO6TdMtKx63OAAB3d3cuZXhhbXBsZS5jb20AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAVGVzdAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABPSyAtIFRlc3RpbmcgZmluZQAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
__[ packet_2 ]__
AAMAAA2eTvFKx63OAAB3d3cuZXhhbXBsZS5jb20AMlQ3R21hOE43Tk9sUTEzNEdKb250MFF3VVox
cUNqQzd4ZFZEMExqNEQ5QUQ4QzlRVGVzdAA3Y1lnOVBNTkZlMEQ4dXlQQXVMRkpsendEa29aSFVt
bmxSUVgxc3lVTWsyM0VNdDdOWjdQN3BrNWZhVkVHb3JNRm4xQlJkdFlJaTBONjA0dDRhTHZFSnZw
RTdSQzYyUjFuRnNjQlhqMktJbUR5bXk1Rjd6WjFaNk1LVjRPSyAtIFRlc3RpbmcgZmluZQBmNVJs
ZTdJNGk1YnE1VkRQeU03OGpHOWNqNGl1djFTdWJ4WER4WTRJWEt1VDNkNlhWczNXaGJiNndJTFBC
RkdUUW5naXFxOFZ6QzVUZW5CTEVtUFlVTjh4OEtjaTZOSTZmY1R1RzcwRzJsV2N6M2RjSlY5QzY5
Zk1hQ0JpcjA2bXZIYlFQQmFOTnFGWXN1TVJSNDJqbXZsZmpUT3hHMjhXQWRicjh5RXA5eGF4Z0ND
cG1vREN1cVozQVI1NkZIbzBLZjVINm1hOXo3OEJzSGpmam1nbk55SWxkU0xuNVVtS2Q3VHN5VkNq
YVI2aHdjNVVZN1p5bnAxMjRGTTFzYUhGQ285MGFVRk84SXhMbnVmSGRnc1RVcnVyOHNvRFlTVGJ5
RVFqSGdCMnhEakZ5emE1dDdhb3VSQ2FGN0hGbWtNczFZbDB4M2N0VUxsWlpEbW1FNzd6WVNVWHIy
bll1bGZxVUhGUFpIOHE5QkJWelA1VXN6UXVwTnhWdTZhdDdKVjJrMEVLVXQ5ZXF1ZjM1RTZUTXhJ
RldraHczaUR6ZW0yWThDbm43bkxPZFc1QmhBUHh1aFJKT1M5MTl2S0tHWjk3YXVIZjJrWHluc2hX
MXZOSmV5ZFRSMDlKNFl2TW9MZVJFQ1dwOUhlenZma2NHYwAA
