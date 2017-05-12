#!/usr/bin/perl
# vim: ts=2 sw=2 filetype=perl expandtab

# Dave Davis' test case for rt.cpan.org ticket #13557:
# "Zero length content header causes request to not post back".

use warnings;
use strict;

BEGIN {
  my @proxies = grep /^http.*proxy$/i, keys %ENV;
  delete @ENV{@proxies} if @proxies;
}

use Test::More;
use Test::POE::Server::TCP;
use POE qw(Filter::Stream Component::Client::HTTP);
use HTTP::Request::Common qw(GET);

POE::Component::Client::HTTP->spawn( Alias => 'ua' );

plan tests => 6;

POE::Session->create(
  inline_states => {
    _start => \&start,
    testd_registered => \&testd_start,
    testd_client_input => \&testd_input,
    zero_length_response => \&zero_length_response,
    nonzero_length_response => \&nonzero_length_response,
  },
);

sub start {
  my $heap = $_[HEAP];

  $heap->{testd} = Test::POE::Server::TCP->spawn(
    Filter => POE::Filter::Stream->new,
    address => 'localhost',
  );
}

sub testd_start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  
  my $port = $heap->{testd}->port;

  # Fetch a URL that has no content.
  $kernel->post(
      'ua', 'request', 'zero_length_response',
      GET "http://localhost:$port/misc/no-content.html"
    );

# Control test: Fetch a URL that has some content.
  $kernel->post(
      'ua', 'request', 'nonzero_length_response',
      GET "http://localhost:$port/misc/test.html"
    );
}

sub testd_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];

  pass("Got request; sending reply");
  my $data;
  if ($input =~ /no-content/) {
    $data = <<'EOF';
HTTP/1.1 200 OK
Connection: close
Content-Length: 0

EOF
  } else {
    $data = <<'EOF';
HTTP/1.1 200 OK
Connection: close
Content-Length: 7

content
EOF
  }
  $heap->{testd}->send_to_client($id, $data);
}

sub zero_length_response {
  my ($request_packet, $response_packet) = @_[ARG0, ARG1];
  my $request_object  = $request_packet->[0];
  my $response_object = $response_packet->[0];

  pass("... got a response");
  is($response_object->content, '', "... and it has no content");
}

sub nonzero_length_response {
  my ($request_packet, $response_packet) = @_[ARG0, ARG1];
  my $request_object  = $request_packet->[0];
  my $response_object = $response_packet->[0];

  pass("... got a response");
  isnt($response_object, '', "... and it has content");
  $_[HEAP]->{testd}->shutdown;
  $_[KERNEL]->post( ua => 'shutdown' );
}

POE::Kernel->run();
exit;
