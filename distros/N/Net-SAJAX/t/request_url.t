#!/usr/bin/perl -T

use lib 't/lib';
use strict;
use warnings 'all';

use Test::More tests => 7;
use Test::Net::SAJAX::UserAgent;

use Net::SAJAX;

###########################################################################
# CONSTRUCT SAJAX OBJECT
my $sajax = new_ok('Net::SAJAX' => [
	url        => 'http://example.net/app.php',
	user_agent => Test::Net::SAJAX::UserAgent->new,
], 'Object creation');

###########################################################################
# CHECK PROPER REQUEST URLS [GET]
{
	# Check the function name was included
	like($sajax->call(function => 'EchoUrl', method => 'GET'),
		qr{rs=EchoUrl}msx, '[GET ] Function name in URL');

	# Check argument was included
	like($sajax->call(function => 'EchoUrl', method => 'GET', arguments => [400]),
		qr{rsargs(?i:%5b%5d)=400}msx, '[GET ] Argument in URL');
}

###########################################################################
# CHECK PROPER REQUEST URLS [POST]
{
	# Check the function name was not included
	unlike($sajax->call(function => 'EchoUrl', method => 'POST'),
		qr{rs=EchoUrl}msx, '[POST] Function name not in URL');

	# Check argument was not included
	unlike($sajax->call(function => 'EchoUrl', method => 'POST', arguments => [400]),
		qr{rsargs(?i:%5b%5d)=400}msx, '[POST] Argument not in URL');
}

###########################################################################
# Change the app URL to include a query parameter
$sajax->url('http://example.net/app.php?key=jabber');

###########################################################################
# CHECK PROPER REQUEST URLS [GET]
{
	# Check the custom query was included
	like($sajax->call(function => 'EchoUrl', method => 'GET'),
		qr{key=jabber}msx, '[GET ]Custom query in URL');
}

###########################################################################
# CHECK PROPER REQUEST URLS [POST]
{
	# Check the custom query was included
	like($sajax->call(function => 'EchoUrl', method => 'POST'),
		qr{key=jabber}msx, '[POST] Custom query in URL');
}
