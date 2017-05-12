use strict;

sub DEBUG () { 0 }

use POE qw[Component::Curl::Multi];
use HTTP::Request::Common qw[GET POST];
use Test::More;

plan tests => 2;

$| = 1;

sub client_start {
  my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];

  DEBUG and warn "client starting...\n";

  my $secure_request = GET(
    'http://google.com/',
    Connection => 'close',
  );

  $kernel->post(
    weeble => request =>
    {
      request  => $secure_request,
      response => $session->postback( 'got_response' ),
      tag      => 'Hello, MacDuff',
    },
  );
}

sub client_stop {
  DEBUG and warn "client stopped...\n";
}

sub client_got_response {
  my ($heap, $kernel) = @_[HEAP, KERNEL];
  my ($request_packet,$response_packet) = @{ $_[ARG1] };
  my $http_request  = $request_packet->[0];
  my $tag           = $request_packet->[1];
  my $http_response = $response_packet->[0];

  DEBUG and do {
    warn "client got request...\n";

    warn $http_request->as_string;
    my $response_string = $http_response->as_string();
    $response_string =~ s/^/| /mg;

    warn ",", '-' x 78, "\n";
    warn $response_string;
    warn "`", '-' x 78, "\n";
  };

  is ($http_response->code, 200, 'Got OK response');
  is ($tag, 'Hello, MacDuff', 'Tag is okay' );

  $kernel->post( weeble => 'shutdown' );
}

# Create a weeble component.
my $curl = POE::Component::Curl::Multi->spawn(
  Alias   => 'weeble',
  Timeout => 60,
  FollowRedirects => 5,
);

# Create a session that will make some requests.
POE::Session->create(
  inline_states => {
    _start              => \&client_start,
    _stop               => \&client_stop,
    got_response        => \&client_got_response,
  }
);

# Run it all until done.
$poe_kernel->run();

exit;
