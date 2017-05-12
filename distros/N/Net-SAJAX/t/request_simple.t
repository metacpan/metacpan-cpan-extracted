#!/usr/bin/perl -T

use lib 't/lib';
use strict;
use warnings 'all';

use Test::More tests => 16;
use Test::Fatal;
use Test::Net::SAJAX::UserAgent;

use Net::SAJAX;

###########################################################################
# CONSTRUCT SAJAX OBJECT
my $sajax = new_ok('Net::SAJAX' => [
	url        => 'http://example.net/app.php',
	user_agent => Test::Net::SAJAX::UserAgent->new,
], 'Object creation');

###########################################################################
# REQUEST RETURNING A NUMBER
{
	my $number;

	# GET A RANDOM NUMBER
	is(exception {$number = $sajax->call(function => 'GetNumber')}, undef, 'Get a number');
	like($number, qr{\A \d+ \z}msx, 'Got a number');
	is(exception {$number = $sajax->call(function => 'GetNumber')}, undef, 'Get a number');
	like($number, qr{\A \d+ \z}msx, 'Got a number');

	# ECHO BACK THE SUPPLIED NUMBER
	is(exception {$number = $sajax->call(
		function  => 'GetNumber',
		arguments => [1234]
	)}, undef, 'Get a number');
	is($number, 1234, 'Got expected number');
}

###########################################################################
# REQUEST BAD FUNCTION
{
	my $data;

	# Non-existant function
	isnt(exception {$sajax->call(function => 'IDoNotExist')}, undef, 'Call a bad function');

	# Function stripping whitespace
	is(exception {$data = $sajax->call(
		function  => 'Echo',
		arguments => ["      \n\n\n\n\t+:'I am test :)'   \n\n\n\n"],
	)}, undef, 'Function returns lots of whitespace');
	is($data, 'I am test :)', 'Whitespace stripped as expected');
}

###########################################################################
# REQUEST WITH TARGET ID
{
	my $data;

	is(exception { $sajax->target_id('test_target') }, undef, 'Set the target id');
	is(exception { $data = $sajax->call(function => 'EchoTargetId') }, undef, 'Request with target ID');
	is($data, 'test_target', 'Got request ID back');
}

###########################################################################
# REQUEST WITH RANDOM KEY
{
	my $data;

	is(exception { $sajax->send_rand_key(1) }, undef, 'Send the random key with requests');
	is(exception { $data = $sajax->call(function => 'EchoRandKey') }, undef, 'Request with random key');
	like($data, qr{\A \d+ \z}msx, 'Got request random key');
}
