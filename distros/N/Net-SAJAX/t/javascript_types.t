#!/usr/bin/perl -T

use lib 't/lib';
use strict;
use warnings 'all';

use Test::More tests => 27;
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
# VERFIY TYPES ARE UNWRAPPED FINE
{
	# List of strings to unwrap
	my @tests = (
		['Object' => '+:o = {"key":"value"}', {key => 'value'}],
		['Array' => '+:a = ["a","b"]', [qw(a b)]],
		['Boolean (true)' => '+:b = true', !!1],
		['Boolean (false)' => '+:b = false', !!0],
		['Boolean (object)' => '+:b = new Boolean(1)', !!1],
		['Null' => '+:n = null', undef],
		['Number' => '+:n = 55', 55],
		['Number (object)' => '+:n = new Number(33)', 33],
		['String' => '+:s = "test string"', 'test string'],
		['String (object)' => '+:s = new String("string thing")', 'string thing'],
		['Undefined' => '+:u = undefined', undef],
	);

	for my $test (@tests) {
		my $data;

		is(exception {$data = $sajax->call(
			function  => 'Echo',
			arguments => [$test->[1]],
		)}, undef, $test->[0] . ' request succeeded');
		is_deeply($data, $test->[2], $test->[0] . ' unwrapped');
	}

	# Regular expression
	{
		my $data;

		is(exception {$data = $sajax->call(
			function  => 'Echo',
			arguments => ['+:r = new RegExp("test1*")'],
		)}, undef, 'Regular expression (object) request succeeded');
		like($data, qr/test1\*/, 'Regular expression (object) unwrapped');
	}

	# Date
	{
		my $data;

		is(exception {$data = $sajax->call(
			function  => 'Echo',
			arguments => ['+:r = new Date(2010, 10, 12, 3, 30, 14)'],
		)}, undef, 'Date (object) request succeeded');
		like($data, qr/\AFri Nov 12 03:30:14 2010/, 'Date (object) unwrapped');
	}
}
