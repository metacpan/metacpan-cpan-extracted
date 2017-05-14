package SOAP::WSDL::Server::PlackTest;
use parent qw(Test::Class);

use strict;
use warnings;

use Carp;
use Test::More;
use Test::Exception;
use HTTP::Request::Common qw(GET POST PUT DELETE);
use HTTP::Status qw(:constants);
use Plack::Test;
# You may add this to trace SOAP calls
#use SOAP::Lite +trace => [qw(all)];

use SOAP::WSDL::Server::Plack;

use Example::Server::HelloWorld::HelloWorldSoap;
use Example::Interfaces::HelloWorld::HelloWorldSoap;

# As SOAP::WSDL client use LWP, we have to use a real HTTP server
# instead of the L<Plack::Test> MockHTTP default method.
$Plack::Test::Impl = 'Server';

sub server_test : Test(6) {
	my ($self) = @_;

	my $app = SOAP::WSDL::Server::Plack->new({
		dispatch_to => 'Example::HelloWorldImpl',
		soap_service => 'Example::Server::HelloWorld::HelloWorldSoap',
	})->psgi_app();

	test_psgi $app, sub {
		my $cb = shift;
		my $request = GET '/';
		my $res = $cb->($request);
		is($res->code, HTTP_LENGTH_REQUIRED);

		# steal uri from request
		my $uri = $request->uri->clone();
		$uri->path('/');
		note 'Temporary web server url: ' . $uri;

		my $if = Example::Interfaces::HelloWorld::HelloWorldSoap->new({
			proxy => $uri->as_string(),
		});

		my $response;
		lives_ok(sub {
			$response = $if->sayHello({
				name => 'Wall',
				givenName => 'Larry',
			});
		}, 'Calling interface works');

		ok($response, 'Got successful result');
		unless ($response) {
			diag "$response";
		}
		is($response->get_sayHelloResult(), 'Hello Larry Wall');
	};
}

1;
