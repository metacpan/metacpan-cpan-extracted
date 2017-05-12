# vim: filetype=perl sw=2 ts=2 expandtab

use strict;

BEGIN {
  my @proxies = grep /^http.*proxy$/i, keys %ENV;
  delete @ENV{@proxies} if @proxies;
}

#sub POE::Kernel::ASSERT_DEFAULT () { 1 }

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
200 OK HTTP/1.1
Connection: close
Content-Length: 300
Bogus-Header: crap

EOF

chomp $long;
$long .= "\n" . "x" x 300;

my $data = <<EOF;
200 OK HTTP/1.1
Connection: close
Content-Length: 118
Content-Type: text/html

<html>
<head><title>Test Page</title></head>
<body><p>This page exists to test POE web components.</p></body>
</html>
EOF

use HTTP::Request::Common qw(GET POST);

#my $cm = POE::Component::Client::Keepalive->new;
POE::Component::Client::HTTP->spawn(
  #MaxSize => MAX_BIG_REQUEST_SIZE,
  MaxSize => 200,
  Timeout => 3,
  #Protocol => 'HTTP/1.1', #default
  #ConnectionManager => $cm, #default
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
  ],
  inline_states => {
    testd_client_flushed => sub { undef },
    testd_connected      => sub { undef },
    testd_disconnected   => sub { undef },
    _stop                => sub { undef },
  },
);

$poe_kernel->run;
exit 0;

sub _start {
  $_[HEAP]->{testd} = Test::POE::Server::TCP->spawn(
    filter => POE::Filter::Stream->new,
    address => 'localhost',
  );
  my $port = $_[HEAP]->{testd}->port;
  my @badrequests = (
    GET("http://not.localhost.but.invalid/badhost"),
    GET("file:///from/a/local/filesystem"),
  );

  my @fields = ('field1=111&', 'field2=222');

  @requests = (
    GET("http://localhost:$port/test", Connection => 'close'),
    GET("http://localhost:$port/timeout", Connection => 'close'),
    POST("http://localhost:$port/post1", [field1 => '111', field2 => '222']),
    GET("http://localhost:$port/long", Connection => 'close'),
    HTTP::Request->new(
      POST => "http://localhost:$port/post2",
      [], sub { return shift @fields }
    ),
    @badrequests,
  );
  
  plan tests => @requests * 2 - @badrequests;
}

sub testd_registered {
  my ($kernel) = $_[KERNEL];

  foreach my $r (@requests) {
    $kernel->post(
      'weeble',
      request => 'got_response',
      $r,
    );
  }
}

sub send_after_timeout {
  my ($heap, $id) = @_[HEAP, ARG0];

  $heap->{testd}->send_to_client($id, $data);
  $heap->{testd}->shutdown;
  $_[KERNEL]->post( weeble => 'shutdown' );
}

sub testd_client_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];

  $heap->{input_buffer} .= $input;
  my $buffer = $heap->{input_buffer};

  if ($buffer =~ /^GET \/test/) {
    pass("got test request");
    $heap->{input_buffer} = "";
    $heap->{testd}->send_to_client($id, $data);
  }
  elsif ($buffer =~ /^GET \/timeout/) {
    pass("got test request we will let timeout");
    $heap->{input_buffer} = "";

    $kernel->delay_add('send_after_timeout', 3.3, $id);
  }
  elsif ($buffer =~ /^POST \/post1.*field.*field/s) {
    pass("got post request with content");
    $heap->{input_buffer} = "";
    $heap->{testd}->send_to_client($id, $data);
  }
  elsif ($buffer =~ /^POST \/post(\d)/) {
    if ($buffer =~ /field.*field/) {
      pass("got content for post request with callback");
      $heap->{input_buffer} = "";
      $heap->{testd}->send_to_client($id, $data);
    }
  }
  elsif ($buffer =~ /^GET \/long/) {
    pass("sending too much data as requested");
    $heap->{input_buffer} = "";
    $heap->{testd}->send_to_client($id, $long);
  }
  else {
    diag("INPUT: $input");
    diag("unexpected test");
  }
}

sub got_response {
  my ($kernel, $heap, $request_packet, $response_packet) = @_[KERNEL, HEAP, ARG0, ARG1];

  my $request = $request_packet->[0];
  my $response = $response_packet->[0];

  my $request_path = $request->uri->path . ''; # stringify

  if ($request_path =~ m/\/test$/ and $response->code == 200) {
    pass('got 200 response for test request')
  }
  elsif ($request_path =~ m/timeout$/ and $response->code == 408) {
    pass('got 408 response for timed out request')
  }
  elsif ($request_path =~ m/\/post\d$/ and $response->code == 200) {
    pass('got 200 response for post request')
  }
  elsif ($request_path =~ m/\/long$/ and $response->code == 406) {
    pass('got 400 response for long request')
  }
  elsif (
    $request_path =~ m/badhost$/ and
    (
      $response->code == 500 or
      $response->code == 408 or
      $response->code == 303     # some DNS's redirect bad hosts
    )
  ) {
    pass("got " . $response->code . " response for request on bad host")
  }
  elsif ($request_path =~ m/filesystem$/ and $response->code == 400) {
    pass('got 400 response for request with unsupported scheme')
  }
  else {
    fail("unexpected response");
    diag("path($request_path) code(" . $response->code() . ")");
    diag("response(((");
    diag($response->as_string);
    diag(")))");
  }
}
