#!/usr/bin/perl -T

use lib 't/lib';
use strict;
use warnings 'all';

use Test::More tests => 10;
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
# BAD ARGUMENTS TO CALL METHOD
{
	isa_ok(exception { $sajax->call() },
		'Net::SAJAX::Exception::MethodArguments',
		'No arguments causes an exception'
	);

	isa_ok(exception { $sajax->call(function => 'Something', method => 'Something') },
		'Net::SAJAX::Exception::MethodArguments',
		'Unknown method causes an exception'
	);

	isa_ok(exception { $sajax->call(function => 'Something', arguments => 'Something') },
		'Net::SAJAX::Exception::MethodArguments',
		'Arguments not an ARRAYREF causes an exception'
	);

	isa_ok(exception { $sajax->call(function => 'Something', arguments => [1,[2]]) },
		'Net::SAJAX::Exception::MethodArguments',
		'Arguments containing a reference causes an exception'
	);
}

###########################################################################
# BAD SERVER RESPONSE
{
	isa_ok(exception { $sajax->call(function => 'EchoStatus', arguments => [500]) },
		'Net::SAJAX::Exception::Response',
		'Bad server response causes an exception'
	);

	isa_ok(exception { $sajax->call(function => 'Echo', arguments => ['']) },
		'Net::SAJAX::Exception::Response',
		'Unparseable response causes an exception'
	);
}

###########################################################################
# SERVER ERROR RESPONSE
{
	isa_ok(exception { $sajax->call(function => 'IDoNotExist') },
		'Net::SAJAX::Exception::RemoteError',
		'Error message from server causes an exception'
	);
}

###########################################################################
# SERVER ERROR RESPONSE
{
	isa_ok(exception { $sajax->call(function => 'Echo', arguments => ['ia@#saf sdafuwbgf']) },
		'Net::SAJAX::Exception::JavaScriptEvaluation',
		'Invalid JavaScript causes an exception'
	);
}

###########################################################################
# UNSUPPORTED JAVASCRIPT OBJECT
{
	isa_ok(exception { $sajax->call(function => 'Echo', arguments => ['+:new Function();']) },
		'Net::SAJAX::Exception::JavaScriptConversion',
		'Unsupported JavaScript object causes an excpetion'
	);
}
