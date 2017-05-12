#
#
use Test::More tests => 3;

use Net::Curl::Simple;
use Net::Curl::Simple::UserAgent;
use Net::Curl::Simple::Async;
use Net::Curl::Simple::Form;

is(
	$Net::Curl::Simple::VERSION,
	$Net::Curl::Simple::UserAgent::VERSION,
	'UA version matches'
);
is(
	$Net::Curl::Simple::VERSION,
	$Net::Curl::Simple::Async::VERSION,
	'Async version matches'
);
is(
	$Net::Curl::Simple::VERSION,
	$Net::Curl::Simple::Form::VERSION,
	'Form version matches'
);
