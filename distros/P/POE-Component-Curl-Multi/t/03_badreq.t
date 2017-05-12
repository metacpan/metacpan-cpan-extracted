use strict;

sub DEBUG () { 0 }

use POE qw[Component::Curl::Multi];
use HTTP::Request::Common qw[GET POST];
use Test::More;

=for comment
unless (grep /SSLify/, keys %INC) {
  plan skip_all => 'Need POE::Component::SSLify to test SSL';
}

if ( $^O eq 'MSWin32' ) {
  plan skip_all => 'POE::Component::SSLify does not work on MSWin32. Please help the author if you can fix this!';
}

=cut

plan tests => 1;

$| = 1;

sub client_start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  DEBUG and warn "client starting...\n";

  my $secure_request = 'http://completely.made.up.url.bogus/';

  $kernel->post(
    weeble => request => got_response =>
    $secure_request,
  );
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

  is ($http_response->code, 400, 'Got the right response');

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
