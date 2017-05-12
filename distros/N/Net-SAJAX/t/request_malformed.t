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
# REQUEST RETURNING HTML
{
	isnt(exception {$sajax->call(
		function  => 'Echo',
		arguments => ['I am some text!'],
	)}, undef, 'Returned plain text');

	isnt(exception {$sajax->call(
		function  => 'Echo',
		arguments => ['<html><body>HTML Body</body></html>'],
	)}, undef, 'Return HTML');

	isnt(exception {$sajax->call(
		function  => 'Echo',
		arguments => ['<script>var res="test";</script>res;'],
	)}, undef, 'Return HTML');

	isnt(exception {$sajax->call(
		function  => 'Echo',
		arguments => ['+:<script>var res="test";</script>res;'],
	)}, undef, 'Return HTML');

	isnt(exception {$sajax->call(
		function  => 'Echo',
		arguments => ["<html><head>\n\n+:var res='test'; res;"],
	)}, undef, 'HTML returned before SAJAX');
}
