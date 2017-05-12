#! /usr/bin/env perl
# test internal functions that won't normally be called by a generic user of this module
# these tests will be the most likely ones in need of rewriting if major refactoring is done
use strict;
use warnings;
use Data::Dumper;

use REST::Consumer;
use HTTP::Response;
use LWP::UserAgent;
use Test::More tests => 14;


# verify that the base url of the service is assembled correctly
{
	my $client;
	$client = REST::Consumer->new( port => 80, host => 'localhost');
	is ($client->get_service_base_url(),'http://localhost:80','base service url');

	$client = REST::Consumer->new( port => 80, host => 'http://localhost');
	is ($client->get_service_base_url(),'http://localhost:80','base service url with http');

	$client = REST::Consumer->new( port => 80, host => 'https://localhost');
	is ($client->get_service_base_url(),'https://localhost:80','base service url with https');
}

# test that the uri contains the host, port, and params
{
	my $client = REST::Consumer->new(
		port => 80,
		host => 'localhost',
	);

	is(
		$client->get_uri(
			path => '/',
			params => {id => 101}
		),
		'http://localhost:80/?id=101',
		'uri contains host, port, path, and params'
	);
}

# test deserialization of json content
{
	my $response = HTTP::Response->new(200);
	$response->content_type('application/json');
	$response->content('{"10":{"cat":"5","dog":"10"}}');

	my $invocation = REST::Consumer::HandlerInvocation->new(
		response => $response,
	);
	
	my $deserialized_content = $invocation->parsed_response;

	is_deeply($deserialized_content,
			{
				'10' => {
					'cat' => '5',
					'dog' => '10'
				}
			},
			"json data parsed"
	);
}


# test that keep alive creates a persistent LWP instance
my $keep_alive_ua;
{
	my $client = REST::Consumer->new(
		port => 80,
		host => 'localhost',
		keep_alive => 1,
		timeout => 123,
	);

	my $ua = $client->get_user_agent();
	is(defined($ua->conn_cache()),1,'lwp keep_alive set');

	$keep_alive_ua = $ua;
}

{
	my $no_keep_alive_client = REST::Consumer->new(
		port => 80,
		host => 'localhost',
		timeout => 123,
	);

	my $ua = $no_keep_alive_client->get_user_agent();
	is(defined($ua->conn_cache()), 1,'lwp keep_alive is on by default');
}

{
	my $client = REST::Consumer->new( port => 80, host => 'localhost', timeout => 123);
	my $ua = $client->get_user_agent();
	ok defined $ua->default_headers->header('User-Agent'), 'has a user agent defined';
	is $ua->default_headers->header('Accept'), 'application/json', 'has accept header defined';
}

# verify that useragent is globally available when keep alive is active
# check that we have the same lwp instance as before
#{
#	my $client = REST::Consumer->new(
#		port => 80,
#		host => 'localhost',
#		keep_alive => 1,
#		timeout => 123,
#	);
#
#	my $ua = $client->get_user_agent();
#
#	# verify memory reference is identical
#	is($ua,$keep_alive_ua,'global lwp instance when keep_alive is on');
#}



# test that the HTTP::Request object gets created correctly
{
	my $client = REST::Consumer->new(
		port => 80,
		host => 'localhost',
		auth => {
			type     => 'basic',
			username => 'MrMonkey',
			password => 'tophat',
		},
	);

	my $request = $client->get_http_request(
		method => 'POST',
		path => 'path/to/resource',
		content => {field1 => 'a', field2 => ['b','c']},
		content_type => 'multipart/form-data',
		headers => [
			'x-dessert' => 'ice cream',
		],
	);

	is_deeply($request->content(),
		{field1 => 'a', field2 => ['b','c']},
		'content was added to http request object',
	);

	my $headers = $request->headers();

	is($headers->header('content-type'),'multipart/form-data','content type header was set in http request');
	is($headers->header('authorization'),'Basic TXJNb25rZXk6dG9waGF0','auth header was set in http request');
	is($headers->header('x-dessert'),'ice cream','custom header was set in http request');
	is($request->uri()->as_string(),'http://localhost:80/path/to/resource','uri was set in http request');
}
