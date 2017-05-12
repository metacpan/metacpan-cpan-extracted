#!/usr/bin/perl -w
# vim: ts=2 sw=2 filetype=perl expandtab

use strict;

BEGIN {
  my @proxies = grep /^http.*proxy$/i, keys %ENV;
  delete @ENV{@proxies} if @proxies;
}

use HTTP::Request::Common qw(GET);
use Test::More;

sub DEBUG () { 0 }
sub POE::Kernel::ASSERT_DEFAULT () { DEBUG }

use POE qw(Component::Client::HTTP Filter::Stream);
use Test::POE::Server::TCP;


sub MAX_BIG_REQUEST_SIZE  () { 4096 }
sub MAX_STREAM_CHUNK_SIZE () { 1024 }  # Needed for agreement with test CGI.

plan tests => 1;

# Create the HTTP client session.

POE::Component::Client::HTTP->spawn(
  Streaming => MAX_STREAM_CHUNK_SIZE,
  Alias     => "streamer",
);

# Create a session that will make and handle some requests.

POE::Session->create(
  inline_states => {
    _start               => \&client_start,
    _stop                => \&client_stop,
    got_response         => \&client_got_response,
    got_timeout          => \&client_timeout,
    testd_registered     => \&testd_start,
    testd_client_input   => \&testd_input,
    testd_disconnected   => \&testd_disc,
    testd_client_flushed => \&testd_out,
  }
);

# Run it all until done.

my $head = <<EOF;
HTTP/1.1 200 OK
Connection: close
Transfer-Encoding: chunked

EOF

POE::Kernel->run();
exit;

### Event handlers begin here.

sub client_start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  DEBUG and warn "client starting...\n";

  $heap->{testd} = Test::POE::Server::TCP->spawn(
    Filter => POE::Filter::Stream->new,
    address => 'localhost',
  );
}

sub testd_start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  my $port = $heap->{testd}->port;
  $kernel->post(
    streamer => request => got_response =>
    GET(
      "http://localhost:$port/misc/chunk-test.cgi",
      Connection => 'close',
    ),
  );
}

sub testd_out {
  my ($kernel, $heap, $id) = @_[KERNEL, HEAP, ARG0];

  return unless ($heap->{datachar} < 26);

  my $data = "200\n";
  my $chr = ord('A') + $heap->{datachar}++;
  $data .= chr($chr) x 512 . "\n";
  $heap->{testd}->send_to_client($id, $data);
}

sub testd_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];

  $heap->{testd}->send_to_client($id, $head);
  $heap->{datachar} = 0;
}

sub client_stop {
  DEBUG and warn "client stopped...\n";
}

sub testd_disc {
  DEBUG and warn "server got disconnected...";
  $_[HEAP]->{testd}->shutdown;
  delete $_[HEAP]->{testd};
}

my $total_octets_got = 0;
my $chunk_buffer = "";
my $next_chunk_character = "A";

sub client_got_response {
  my ($heap, $request_packet, $response_packet) = @_[HEAP, ARG0, ARG1];
  my $http_request = $request_packet->[0];
  my ($http_headers, $chunk) = @$response_packet;

  DEBUG and do {
    warn "client got stream response...\n";

    my $response_string = $http_headers->as_string();
    $response_string =~ s/^/| /mg;

    warn (
      ",", '-' x 78, "\n",
      $response_string,
      "`", '-' x 78, "\n",
      ($chunk ? $chunk : "(undef)"), "\n",
      "`", '-' x 78, "\n",
    );
  };

  if (defined $chunk) {
    $chunk_buffer .= $chunk;
    $total_octets_got += length($chunk);
    while (length($chunk_buffer) >= MAX_STREAM_CHUNK_SIZE) {
      my $next_chunk = substr($chunk_buffer, 0, MAX_STREAM_CHUNK_SIZE);
      substr($chunk_buffer, 0, MAX_STREAM_CHUNK_SIZE) = "";
      $next_chunk_character++;
    }
    $_[KERNEL]->call( streamer => cancel => $_[ARG0][0] );
    $_[KERNEL]->delay( got_timeout => 2 );
    return;
  }

  $total_octets_got += length($chunk_buffer);
  is($total_octets_got, MAX_STREAM_CHUNK_SIZE, "Got the right amount of data");
}

sub client_timeout {
  $_[KERNEL]->post( weeble => 'shutdown' );
}
