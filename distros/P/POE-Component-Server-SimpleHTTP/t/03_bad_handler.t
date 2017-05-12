use strict;
use warnings;
use Test::More tests => 3;

use POE qw(Component::Server::SimpleHTTP Filter::Stream);
use Test::POE::Client::TCP;
use HTTP::Request;
use HTTP::Response;

POE::Session->create(
   package_states => [
	main => [qw(_start _tests webc_connected webc_input webc_disconnected TOP)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my $session_id = $_[SESSION]->ID();
  POE::Component::Server::SimpleHTTP->new(
                'ALIAS'         =>      'HTTPD',
                'ADDRESS'       =>      '127.0.0.1',
                'PORT'          =>      0,
                'HOSTNAME'      =>      'pocosimpletest.com',
                'HANDLERS'      =>      [
                        {
                                'DIR'           =>      '^/$',
                                'SESSION'       =>      $session_id,
                                'EVENT'         =>      'TOP',
                        },
                ],
                SETUPHANDLER => { SESSION => $session_id, EVENT => '_tests', },
  );
  return;
}

sub _tests {
  my ($kernel,$heap,$sender,$port) = @_[KERNEL,HEAP,SENDER,ARG0];
  $heap->{webc} = Test::POE::Client::TCP->spawn(
	address 	=> '127.0.0.1',
	port    	=> $port,
	autoconnect 	=> 1,
	prefix  	=> 'webc',
	filter		=> POE::Filter::Stream->new(),
  );
  $heap->{port} = $port;
  return;
}

sub webc_connected {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{webc}->send_to_server("GET /rubbish HTTP/1.1\x0D\x0AHost: 127.0.0.1:$heap->{port}\x0D\x0A\x0D\x0A");
  return;
}

sub TOP { 
  my( $request, $response, $dirmatch ) = @_[ ARG0 .. ARG2 ];
  diag($request->as_string);
  $response->code( 200 );
  $response->content("Moo\nMoo\nMoo\nMoo\n");
  $poe_kernel->post( $_[SENDER], 'DONE', $response );
  return;
}

sub webc_input {
  my ($heap,$input) = @_[HEAP,ARG0];
  $heap->{string} .= $input;
  return;
}

sub webc_disconnected {
  my ($heap,$state) = @_[HEAP,STATE];
  pass($state);
  my $response = HTTP::Response->parse( $heap->{string} );
  isa_ok( $response, 'HTTP::Response' ) and 
  	diag($response->as_string);
  ok( $response->code eq '404', 'Got a 404 response from bad handler' );
  $heap->{webc}->shutdown();
  delete $heap->{webc};
  $poe_kernel->post( 'HTTPD', 'SHUTDOWN' );
  return;
}
