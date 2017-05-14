package SOAP::WSDL::Server::PlackTest;
use parent qw(Test::Class);

use strict;
use warnings;

use Carp;
use Test::More;
use Test::Exception;

use SOAP::WSDL::Server::Plack;

# As SOAP::WSDL client use LWP, we have to use a real HTTP server
# instead of the L<Plack::Test> MockHTTP default method.
$Plack::Test::Impl = 'Server';

sub construction_test : Test(5) {
	my ($self) = @_;

	my $soap;
	lives_ok(sub {
		$soap = SOAP::WSDL::Server::Plack->new({
			dispatch_to => 'DOES::NOT::EXIST',
			soap_service => 'DOES::NOT::EXIST::EITHER',
		});
	}, 'constructor with minimal required parameters works');
	isa_ok($soap, 'SOAP::WSDL::Server::Plack');
	can_ok($soap, 'psgi_app');

	dies_ok(sub {
		$soap = SOAP::WSDL::Server::Plack->new({
			soap_service => 'DOES::NOT::EXIST::EITHER',
		});
	}, 'missing "dispatch_to" raises exception');

	dies_ok(sub {
		$soap = SOAP::WSDL::Server::Plack->new({
			dispatch_to => 'DOES::NOT::EXIST',
		});
	}, 'missing "soap_service" raises exception');
}

sub app_test : Test(4) {
	my ($self) = @_;

	use_ok('Example::Server::HelloWorld::HelloWorldSoap');

	my $soap = SOAP::WSDL::Server::Plack->new({
		dispatch_to => 'Example::HelloWorldImpl',
		soap_service => 'Example::Server::HelloWorld::HelloWorldSoap',
	});

	my $app;
	lives_ok(sub {
		$app = $soap->psgi_app();
	});

	ok(defined $app, 'Got something from psgi_app()');
	is(ref($app), 'CODE', 'Got a code ref as app from psgi_app()');
}

sub example_soap_test : Test(3) {
	my ($self) = @_;

	use_ok('Example::Server::HelloWorld::HelloWorldSoap');
	use_ok('Example::Interfaces::HelloWorld::HelloWorldSoap');

	my $app;
	$app = SOAP::WSDL::Server::Plack->new({
		dispatch_to => 'Example::HelloWorldImpl',
		soap_service => 'Example::Server::HelloWorld::HelloWorldSoap',
	})->psgi_app();

	is(ref($app), 'CODE', 'Got a code ref as app from psgi_app()');
}

1;
