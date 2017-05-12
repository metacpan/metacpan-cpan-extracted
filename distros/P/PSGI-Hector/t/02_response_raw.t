use strict;
use warnings;
use Test::More;
plan(tests => 5);
use lib qw(../lib lib);
use PSGI::Hector;
use PSGI::Hector::Response::Raw;

#setup our cgi environment
my %env;
$env{'SCRIPT_NAME'} = "test.cgi";
$env{'SERVER_NAME'} = "www.test.com";
$env{'HTTP_HOST'} = "www.test.com";
$env{'HTTP_REFERER'} = "http://" . $env{'HTTP_HOST'};
$env{'REQUEST_METHOD'} = 'GET';

my $options = {
	'responsePlugin' => 'PSGI::Hector::Response::Raw'
};

my $m = PSGI::Hector->new($options, \%env);

my $raw = $m->getResponse();

#1
ok($raw->setContent('Hello'), 'SetContent()');

{
	my $out = $raw->_getContent();
	#2
	is($out, 'Hello', '_getContent()');
}

#3
ok($raw->setContent(' world'), 'SetContent()');

{
	my $out = $raw->_getContent();
	#4
	is($out, 'Hello world', '_getContent()');
}

{
	$raw->setError("some error");
	my $out = $raw->_getContent();
	#5
	is($out, 'Error: some error', '_getContent() with error');	
}