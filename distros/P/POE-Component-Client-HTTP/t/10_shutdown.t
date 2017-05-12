#!/usr/bin/perl -w
# vim: ts=2 sw=2 filetype=perl expandtab

use strict;

sub DEBUG () { 0 }
sub POE::Kernel::ASSERT_DEFAULT () { DEBUG }

use HTTP::Request::Common qw(GET);
use Test::More;
use Test::POE::Server::TCP;

use POE qw(Component::Client::HTTP);

plan tests => 2;

# Create a weeble component.
POE::Component::Client::HTTP->spawn( Timeout => 2 );

# Create a session that will make some requests.
POE::Session->create(
  inline_states => {
    _start              => \&client_start,
    stop_httpd          => \&client_stop,
    got_response        => \&client_got_response,
    do_shutdown         => \&client_got_shutdown,
    testd_registered    => \&testd_got_setup,
    testd_connected     => \&testd_got_input,
  },
);

# Run it all until done.
$poe_kernel->run();

exit;

sub client_start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  DEBUG and warn "client starting...\n";

  # run a server just in case of a screwup and we *do* get requests.
  $heap->{testd} = Test::POE::Server::TCP->spawn(
    Filter => POE::Filter::Stream->new,
    address => 'localhost',
  );

  $kernel->yield("do_shutdown");
}

sub testd_got_setup {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  DEBUG and warn "client got setup...\n";

  my $port = $heap->{testd}->port;

  for (1..2) {
    $kernel->post(
      weeble => request => got_response =>
      GET("http://localhost:$port/test.html", Connection => 'close'),
    );
  }
}

sub testd_got_input {
  BAIL_OUT('There should be NO requests');
}

sub client_got_shutdown {
  my $kernel = $_[KERNEL];
  DEBUG and warn "client got shutdown...\n";
  $kernel->post(weeble => "shutdown");
}

sub client_stop {
  my $heap = $_[HEAP];
  DEBUG and warn "client stopped...\n";

  if ($heap->{testd}) {
    $heap->{testd}->shutdown;
    delete $heap->{testd};
  }
}

sub client_got_response {
  my ($heap, $kernel, $request_packet, $response_packet) = @_[
    HEAP, KERNEL, ARG0, ARG1
  ];
  my $http_request  = $request_packet->[0];
  my $http_response = $response_packet->[0];

  DEBUG and do {
    warn "client got response...\n";

    warn $http_request->as_string;
    my $response_string = $http_response->as_string();
    $response_string =~ s/^/| /mg;

    warn ",", '-' x 78, "\n";
    warn $response_string;
    warn "`", '-' x 78, "\n";
  };

  # Track how many of each response code we get.
  # Should be two 408s, indicating two connection timeouts.
  is ($http_response->code, 408, "Got the expected timeout");

  # wrong place really, but works since we're not getting anything
  $kernel->yield('stop_httpd');
}
