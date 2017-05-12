use strict;
use warnings;
use Test::More tests => 8;
use POE qw(Filter::Stream);
use POE::Filter::HTTP::Parser;
use Test::POE::Server::TCP;
use Test::POE::Client::TCP;
use HTTP::Request;
use HTTP::Response;

POE::Session->create(
   package_states => [
	main => [qw(
			_start
			httpd_registered
			httpd_client_input
			httpc_connected
			httpc_input
	)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{httpd} = Test::POE::Server::TCP->spawn(
	prefix  => 'httpd',
	address => '127.0.0.1',
	filter  => POE::Filter::HTTP::Parser->new( type => 'server' ),
  );
  return;
}

sub httpd_registered {
  my ($heap,$object) = @_[HEAP,ARG0];
  $heap->{port} = $object->port();
  $heap->{httpc} = Test::POE::Client::TCP->spawn(
	prefix	    => 'httpc',
	autoconnect => 1,
	address     => '127.0.0.1',
	port	    => $heap->{port},
	inputfilter => POE::Filter::HTTP::Parser->new( type => 'client' ),
	outputfilter => POE::Filter::Stream->new(),
  );
  return;
}

sub httpc_connected {
  my $heap = $_[HEAP];
  $heap->{httpc}->send_to_server( "Complete and utter cock\x0D\x0A\x0D\x0A" );
  return;
}

sub httpd_client_input {
  my ($heap,$id,$req) = @_[HEAP,ARG0,ARG1];
  isa_ok( $req, 'HTTP::Response' );
  is( $req->code, '400', 'Ooops something went wrong' );
  is( $req->header('Content-Type'), 'text/html', 'Content-Type' );
  diag($req->as_string);
  $req->protocol('HTTP/1.1');
  $heap->{httpd}->send_to_client( $id, $req );
  return;
}

sub httpc_input {
  my ($heap,$resp) = @_[HEAP,ARG0];
  isa_ok( $resp, 'HTTP::Response' );
  diag($resp->as_string);
  is( $resp->code, '400', 'Ooops something went wrong' );
  is( $resp->header('X-HTTP-Version'), '1.1', 'X-HTTP-Version' );
  is( $resp->header('Content-Type'), 'text/html', 'Content-Type' );
  like( $resp->content, qr/Complete and utter cock/, 'Complete and utter cock' );
  $heap->{httpc}->shutdown();
  $heap->{httpd}->shutdown();
  delete $heap->{$_} for qw(httpd httpc);
  return;
}
