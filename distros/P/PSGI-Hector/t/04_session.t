use strict;
use warnings;
use Test::More;
plan(tests => 5);
use lib qw(../lib lib);
use PSGI::Hector;

#setup our cgi environment
my %env;
$env{'SCRIPT_NAME'} = "test.cgi";
$env{'SERVER_NAME'} = "www.test.com";
$env{'HTTP_HOST'} = "www.test.com:8080";
$env{'HTTP_REFERER'} = "http://" . $env{'HTTP_HOST'};
$env{'SERVER_PORT'} = 8080;
$env{'REQUEST_URI'} = "/test.cgi";
$env{'REQUEST_METHOD'} = 'GET';
$env{'REMOTE_ADDR'} = '1.2.3.4';

my $options = {
	'responsePlugin' => 'PSGI::Hector::Response::Raw',
	'debug' => 1
};

my $m = PSGI::Hector->new($options, \%env);
#1
my $session = PSGI::Hector::Session->new($m);
isa_ok($session, "PSGI::Hector::Session");

#2
{
	my $response = $m->getResponse();
	like($response->header("Set-Cookie"), qr/^SESSION=[A-Z]{2}[a-f0-9]+/, "New session created on new()")
}

#3
{
	ok($session->_validate(), 'Validates with an unchanged remote IP');
}

#4
{
	$env{'REMOTE_ADDR'} = '8.8.8.8';
	ok(!$session->_validate(), 'Does not validate with an different remote IP');
}

#5
{
	ok($session->delete(), 'delete()');
}
