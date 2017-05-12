use strict;
use warnings;
sub POE::Component::Server::SimpleHTTP::DEBUG () { 1 }
use POE qw(Component::Client::HTTP Component::Server::SimpleHTTP);
use POE::Component::Server::SimpleHTTP::Response;

# Stolen from POE::Wheel. This is static data, shared by all
my $current_id = 0;
my %active_identifiers;

sub _allocate_identifier {
  while (1) {
    last unless exists $active_identifiers{ ++$current_id };
  }
  return $active_identifiers{$current_id} = $current_id;
}

sub _free_identifier {
  my $id = shift;
  delete $active_identifiers{$id};
}

my $agent = 'proxy' . $$;
my $httpd = 'HTTPD' . $$;

POE::Component::Client::HTTP->spawn(
  Alias => $agent,
  Streaming => 4096,
);

POE::Component::Server::SimpleHTTP->new(
  KEEPALIVE     =>      1,
  ALIAS         =>      $httpd,
  PORT          =>      11111,
  PROXYMODE	 => 	 1,
  HANDLERS	 =>	 [
	{
          DIR           =>      '.*',
          SESSION       =>      'controller',
          EVENT         =>      'got_request',
	},
  ],
);

POE::Session->create(
   package_states => [
	main => [qw(_start got_request _got_stream _response)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  $poe_kernel->alias_set( 'controller' );
  return;
}

sub got_request {
  my($kernel,$heap,$request,$response,$dirmatch) = @_[KERNEL,HEAP,ARG0..ARG2];
  my $httpd = $_[SENDER]->get_heap();
  use Data::Dumper;
  $Data::Dumper::Indent=1;
  print Dumper( $response );
  # Check for errors
  if ( ! defined $request ) {
     $kernel->post( $httpd, 'DONE', $response );
     return;
  }

  $request->header('Connection', 'Keep-Alive');
  $request->remove_header('Accept-Encoding');

  # Let's see if it is a CONNECT request
  warn $request->as_string;
  warn $request->method, "\n";

  if ( $request->method eq 'CONNECT' ) {
     my $uri = $request->uri;
  #   warn $uri->authority, "\n";
     warn $uri->as_string, "\n";
  }

  $response->stream(
     session     => 'controller',
     event       => '_got_stream',
     dont_flush  => 1
  );

  my $id = _allocate_identifier();
  $kernel->post( 
    $agent, 
    'request',
    '_response',
    $request, 
    "$id",
  );

  $heap->{_requests}->{ $id } = $response;
  return;
}

sub _response {
  my ($kernel,$heap,$request_packet,$response_packet) = @_[KERNEL,HEAP,ARG0,ARG1];
  my $id = $request_packet->[1];
  my $resp = $heap->{_requests}->{ $id };
  
  my $response = _rebless( $resp, $response_packet->[0] );
  my $chunk    = $response_packet->[1];

  warn $response->headers_as_string, "\n";

  if ( $chunk ) {
    $response->content( $chunk );
    $kernel->post( $httpd, 'STREAM', $response );
  }
  else {
    $kernel->post( $httpd, 'DONE', $response );
  }

  return;
}

sub _got_stream {
  my ($kernel,$heap,$response) = @_[KERNEL,HEAP,ARG0];
  return;
}

sub _rebless {
  my ($orig,$new) = @_;
  $new->{$_} = $orig->{$_} for grep { exists $orig->{$_} }
    qw(_WHEEL connection STREAM_SESSION STREAM DONT_FLUSH IS_STREAMING);
  bless $new, 'POE::Component::Server::SimpleHTTP::Response';
  return $new;
}
