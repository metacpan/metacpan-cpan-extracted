use strict;
use warnings;
use Test::More tests => 24;
use POE;
use POE::Filter::HTTP::Parser;
use Test::POE::Server::TCP;
use Test::POE::Client::TCP;
use HTTP::Request;
use HTTP::Response;

my @tests = (
  '/', '/moocow', '/bingos/was/here',
);

POE::Session->create(
   package_states => [
	main => [qw(
			_start
			_run_tests
			httpd_registered
			httpd_client_input
			httpc_connected
			httpc_input
	)],
   ],
   heap => { tests => \@tests, },
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
	filter	    => POE::Filter::HTTP::Parser->new( type => 'client' ),
  );
  return;
}

sub httpc_connected {
  $poe_kernel->yield( '_run_tests' );
  return;
}

sub _run_tests {
  my $heap = $_[HEAP];
  my $test = shift @{ $heap->{tests} };
  my $req = HTTP::Request->new( GET => $test );
  $req->protocol( 'HTTP/1.1' );
  $req->header( 'Host', "127.0.0.1:$heap->{port}" );
  $heap->{httpc}->send_to_server( $req );
  $heap->{current_test} = $test;
  return;
}

sub httpd_client_input {
  my ($heap,$id,$req) = @_[HEAP,ARG0,ARG1];
  my $test = delete $heap->{current_test};
  isa_ok( $req, 'HTTP::Request' );
  is( $req->method, 'GET', 'Request method is GET' );
  is( $req->uri->path, $test, 'Correct path' );
  is( $req->header('X-HTTP-Version'), '1.1', 'X-HTTP-Version' );
  diag($req->as_string);
  my $resp = HTTP::Response->new( 200 );
  $resp->protocol('HTTP/1.1');
  $resp->content('Cows go moo, yes they do');
  use bytes;
  $resp->header('Content-Length', length $resp->content);
  $resp->header('Content-Type', 'text/plain');
  $heap->{httpd}->send_to_client( $id, $resp );
  return;
}

sub httpc_input {
  my ($heap,$resp) = @_[HEAP,ARG0];
  isa_ok( $resp, 'HTTP::Response' );
  diag($resp->as_string);
  is( $resp->header('X-HTTP-Version'), '1.1', 'X-HTTP-Version' );
  is( $resp->header('Content-Type'), 'text/plain', 'Content-Type' );
  is( $resp->content, 'Cows go moo, yes they do', 'Cows go moo, yes they do' );
  if ( scalar @{ $heap->{tests} } ) {
     $poe_kernel->yield( '_run_tests' );
     return;
  }
  $heap->{httpc}->shutdown();
  $heap->{httpd}->shutdown();
  delete $heap->{$_} for qw(httpd httpc);
  return;
}
