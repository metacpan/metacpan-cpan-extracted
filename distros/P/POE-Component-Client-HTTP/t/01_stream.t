# vim: filetype=perl sw=2 ts=2 expandtab

use strict;

BEGIN {
  my @proxies = grep /^http.*proxy$/i, keys %ENV;
  delete @ENV{@proxies} if @proxies;
}

use Test::More;
use POE qw(
  Filter::Stream
  Filter::HTTPD
  Component::Client::HTTP
  Component::Client::Keepalive
);

use Test::POE::Server::TCP;

my @requests;
my $long = <<EOF;
200 OK
Connection: close
Content-Length: 300
Bogus-Header: 
EOF

chomp $long;
$long .= "x" x 300;

my $data = <<EOF;
HTTP/1.1 200 OK
Connection: close
Content-Type: text/plain
Transfer-Encoding: chunked

EOF

$data .= "fe6\n"  . "A" x 1024 . "B" x 1024 . "C" x 1024 . "D" x 998  . "\n";
$data .= "2000\n" . "D" x 26   . "E" x 1024 . "F" x 1024 . "G" x 1024 .
                    "H" x 1024 . "I" x 1024 . "J" x 1024 . "K" x 1024 .
                    "L" x 998  .                                        "\n";
$data .= "2000\n" . "L" x 26   . "M" x 1024 . "N" x 1024 . "O" x 1024 .
                    "P" x 1024 . "Q" x 1024 . "R" x 1024 . "S" x 1024 .
                    "T" x 998  .                                        "\n";
$data .= "181a\n" . "T" x 26   . "U" x 1024 . "V" x 1024 . "W" x 1024 .
                    "X" x 1024 . "Y" x 1024 . "Z" x 1024 .              "\n";
$data .= "0\n";

my @expect = qw(A D L T);
use HTTP::Request::Common qw(GET POST);

#my $cm = POE::Component::Client::Keepalive->new;
POE::Component::Client::HTTP->spawn(
  Streaming => 256,
  Timeout => 2,
);

POE::Session->create(
  package_states => [
    main => [qw(
      _start
      testd_registered
      testd_client_input
      got_response
      send_after_timeout
    )],
  ]
);

$poe_kernel->run;
exit 0;

sub _start {
  $_[HEAP]->{testd} = Test::POE::Server::TCP->spawn(
    filter => POE::Filter::Stream->new,
    address => 'localhost',
  );
  my $port = $_[HEAP]->{testd}->port;
  @requests = (
    GET("http://localhost:$port/stream", Connection => 'close'),
  );
  
  plan tests => @requests * 6;
}

sub testd_registered {
  my ($kernel) = $_[KERNEL];

  foreach my $r (@requests) {
    $kernel->post(
        'weeble',
        request =>
          'got_response', 
          $r,
    );
  }
}

sub send_after_timeout {
  my ($heap, $id) = @_[HEAP, ARG0];

  $heap->{testd}->send_to_client($id, $data);
}

sub testd_client_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];
  if ($input =~ /^GET \/stream/) {
    ok(1, "got test request");
    $heap->{testd}->send_to_client($id, $data);
  } elsif ($input =~ /^GET \/timeout/) {
    ok(1, "got test request we will let timeout");
    $kernel->delay_add('send_after_timeout', 1.1, $id);
  } elsif ($input =~ /^POST \/post.*field/s) {
    ok(1, "got post request with content");
    $heap->{testd}->send_to_client($id, $data);
  } elsif ($input =~ /^GET \/long/) {
    ok(1, "sending too much data as requested");
    $heap->{testd}->send_to_client($id, $long);
  } else {
    die "unexpected test";
  }
}


sub got_response {
  my ($kernel, $heap, $request_packet, $response_packet) = @_[KERNEL, HEAP, ARG0, ARG1];

  my $request = $request_packet->[0];
  my $response = $response_packet->[0];
  my $chunk = $response_packet->[1];

  my $request_path = $request->uri->path . ''; # stringify
  #warn $request_path;
  #warn $response->as_string;

  if ($request_path =~ m/\/stream$/ and $response->code == 200) {
    if (defined $chunk) {
      if (my $next = shift @expect) {
        is(substr($chunk, 0, 1), $next , "chunk starts with $next");
      }
    } else {
      ok(@expect == 0, "got end of stream");
      $heap->{testd}->shutdown;
      $kernel->post( weeble => 'shutdown' );
    }
  } elsif ($request_path =~ m/timeout$/ and $response->code == 408) {
    ok(1, 'got 408 response for timed out request')
  } elsif ($request_path =~ m/\/post$/ and $response->code == 200) {
    ok(1, 'got 200 response for post request')
  } elsif ($request_path =~ m/\/long$/ and $response->code == 406) {
    ok(1, 'got 406 response for long request')
  } elsif ($request_path =~ m/badhost$/ and $response->code == 500) {
    ok(1, 'got 500 response for request on bad host')
  } elsif ($request_path =~ m/filesystem$/ and $response->code == 400) {
    ok(1, 'got 400 response for request with unsupported scheme')
  } else {
    ok(0, "unexpected response");
  }
}
