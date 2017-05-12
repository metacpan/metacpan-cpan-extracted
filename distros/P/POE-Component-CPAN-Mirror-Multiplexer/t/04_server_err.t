use strict;
use warnings;
use Test::More tests => 9;
use POE qw(Filter::HTTP::Parser Component::CPAN::Mirror::Multiplexer);
use Test::POE::Client::TCP;
use HTTP::Request;

POE::Session->create(
  package_states => [
     'main' => [qw(_start _stop _start_tests httpc_connected httpc_input httpc_disconnected _got_request)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{httpd} = POE::Component::CPAN::Mirror::Multiplexer->spawn(
     address => '127.0.0.1',
     port => 0,
     event => '_got_request',
  );

  $kernel->yield( '_start_tests' );
  return;
}

sub _stop {
  pass('Let my people go go');
  return;
}

sub _start_tests {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  unless ( $heap->{httpd}->port ) {
     $kernel->yield( '_start_tests' );
     return;
  }
  $heap->{port} = $heap->{httpd}->port;
  diag($heap->{port});
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
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $req = HTTP::Request->new( GET => '/ThisShouldNeverWorkMmmmmkay.html' );
  $req->protocol( 'HTTP/1.1' );
  $req->header( 'Host', "127.0.0.1:$heap->{port}" );
  $heap->{httpc}->send_to_server( $req );
  return;
}

sub httpc_disconnected {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  pass('Got disconnected');
  $heap->{httpc}->shutdown;
  return;
}

sub httpc_input {
  my ($heap,$resp) = @_[HEAP,ARG0];
  isa_ok( $resp, 'HTTP::Response' );
  ok( !$resp->is_success, 'Successful response' );
#  $heap->{httpc}->shutdown;
  $heap->{httpd}->yield('shutdown');
  return;
}

sub _got_request {
  my ($kernel,$heap,$request,$info) = @_[KERNEL,HEAP,ARG0,ARG1];
  isa_ok( $request, 'HTTP::Request' );
  diag($request->as_string);
  ok( defined $info->{$_}, "Info has '$_'" ) for qw(peeraddr peerport sockaddr sockport);
  return;
}
