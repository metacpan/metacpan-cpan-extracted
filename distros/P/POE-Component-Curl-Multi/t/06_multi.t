use strict;

sub DEBUG () { 0 }

use POE qw[Component::Curl::Multi];
use HTTP::Request::Common qw[GET POST];
use Test::More;

plan tests => 2;

$| = 1;

sub client_start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  $heap->{count} = 2;
  DEBUG and warn "client starting...\n";

  $kernel->post(
    weeble => request => got_response =>
    $_,
  ) for map { GET( $_, Connection => 'close' ) }
    ( 'http://www.google.com', 'http://www.cpan.org' );
}

sub client_stop {
  DEBUG and warn "client stopped...\n";
}

sub client_got_response {
  my ($heap, $kernel, $request_packet, $response_packet) = @_[
    HEAP, KERNEL, ARG0, ARG1
  ];
  my $http_request  = $request_packet->[0];
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

  like ($http_response->code, qr/^[23]/, 'Got OK response')
    or diag( $http_response->as_string );

  $heap->{count}--;
  $kernel->post( weeble => 'shutdown' ) if $heap->{count} <= 0;
}

# Create a weeble component.
my $curl = POE::Component::Curl::Multi->spawn(
  Alias   => 'weeble',
  Timeout => 60,
  FollowRedirects => 0,
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
