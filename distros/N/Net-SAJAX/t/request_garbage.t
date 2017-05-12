#!/usr/bin/perl -T

use lib 't/lib';
use strict;
use warnings 'all';

use Test::More tests => 6;
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
# REQUEST WITH HTML AT TOP
{
	my $data;

	# Disable autocleaning
	$sajax->autoclean_garbage(0);

	isnt(exception {$sajax->call(
		function  => 'Echo',
		arguments => ["<html><head>\n\n+:var res='test'; res;"],
	)}, undef, 'HTML at beginning caused failure');

	# Enable autocleaning
	$sajax->autoclean_garbage(1);

	is(exception {$data = $sajax->call(
		function  => 'Echo',
		arguments => ["<html><head>\n\n+:var res='test'; res;"],
	)}, undef, 'HTML at beginning did not cause failure');
	is($data, 'test', 'Cleaned HTML at beginning');
}

###########################################################################
# REQUEST WITH LOTS OF PHP GARBAGE
{
	my $data;

	# Enable autocleaning
	$sajax->autoclean_garbage(1);

	is(exception {$data = $sajax->call(
		function  => 'Echo',
		arguments => ["<html><head>\n\n<body>+:var res='test'; res;</body></html>"],
	)}, undef, 'Lots of garbage with PHP response');
	is($data, 'test', 'Garbage cleaned');
}
