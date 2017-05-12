# vim: filetype=perl sw=2 ts=2 expandtab

use strict;

BEGIN {
  my @proxies = grep /^http.*proxy$/i, keys %ENV;
  delete @ENV{@proxies} if @proxies;
}

sub DEBUG () { 0 }
#sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use POE qw(Component::Client::HTTP Component::Client::Keepalive);
use Test::POE::Server::TCP;
use HTTP::Request::Common qw(GET);
use Test::More;

$| = 1;

# set max_per_host, so we can more easily determine whether we're
# reusing connections when expected.
my $cm = POE::Component::Client::Keepalive->new(
  max_per_host => 1
);
my @requests;
my $data = <<EOF;
200 OK HTTP/1.1
Server: Test-POE-Server-TCP
CONNECTION
Content-Length: 118
Content-Type: text/html

<html>
<head><title>Test Page</title></head>
<body><p>This page exists to test POE web components.</p></body>
</html>
EOF

sub client_start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  DEBUG and warn "client starting...\n";

  $_[HEAP]->{testd} = Test::POE::Server::TCP->spawn(
    filter => POE::Filter::Stream->new,
    address => 'localhost',
  );
  my $port = $_[HEAP]->{testd}->port;

  @requests = (
    GET("http://localhost:$port/test.cgi?FIRST", Connection => "Keep-Alive"),
    GET("http://localhost:$port/test.cgi?TEST2", Connection => "Keep-Alive"),
    GET("http://localhost:$port/test.cgi?TEST3"),
    GET("http://localhost:$port/test.cgi?TEST4", Connection => "Close"),
    GET("http://localhost:$port/test.cgi?TEST5"),
  );

  #plan 'no_plan';
  plan tests => scalar @requests * 2;
}

sub testd_registered {
  my ($kernel) = $_[KERNEL];

  my $r = shift @requests;
  $kernel->post( weeble => request => got_response => $r );
}

my $ka = "Connection: Keep-Alive\nKeep-Alive: timeout=2, max=100";
my $cl = "Connection: Close";

sub testd_disconnected {
  my ($kernel, $heap, $id) = @_[KERNEL, HEAP, ARG0];
  if ($heap->{do_shutdown}) {
    $heap->{testd}->shutdown;
  } else {
    is($heap->{prevtype}, 'close', "shutting down a 'close' connection");
  }
  #warn "disconnected $id";
}

sub timeout {
  my ($kernel, $heap, $id) = @_[KERNEL, HEAP, ARG0];
  #warn "terminating";
  $heap->{do_shutdown} = 1;
  $heap->{testd}->terminate($id);
}

sub testd_client_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];

#warn $id;
  if (defined $heap->{previd}) {
    if ($heap->{prevtype} eq 'reuse') {
      is($id, $heap->{previd}, "reused connection");
    } else {
      isnt($id, $heap->{previd}, "new connection");
    }
  }
  ##warn $input;
  my $tosend = $data;
  if ($input =~ /Close/) {
    $heap->{testd}->disconnect($id);
    $heap->{prevtype} = 'close';
    $tosend =~ s/CONNECTION/$cl/;
  } else {
    $kernel->delay('timeout', 2, $id);
    $heap->{prevtype} = 'reuse';
    $tosend =~ s/CONNECTION/$ka/;
  }
  $heap->{previd} = $id;
  $heap->{testd}->send_to_client($id, $tosend);
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

  # DEBUG and "client SECOND_RESPONSE: START";

  DEBUG and do {
    warn "client got request...\n";

    my $response_string = $http_response->as_string();
    $response_string =~ s/^/| /mg;

    warn ",", '-' x 78, "\n";
    warn $response_string;
    warn "`", '-' x 78, "\n";
  };

  my $request_path = $http_request->uri->path . ''; # stringify
  my $request_uri  = $http_request->uri       . ''; # stringify

  is($http_response->code, 200, "got OK response code");

  if (@requests) {
  $kernel->post(weeble => request => got_response => shift @requests);
  } else {
    # TODO: figure out why this doesn't trigger an immediate
    # disconnect on the testd.
    $cm->shutdown;
    $cm = undef;
  }
}

#------------------------------------------------------------------------------

# Create a weeble component.
POE::Component::Client::HTTP->spawn(
  #MaxSize           => MAX_BIG_REQUEST_SIZE,
  Timeout           => 2,
  ConnectionManager => $cm,
);

# Create a session that will make some requests.
POE::Session->create(
  inline_states => {
    _start              => \&client_start,
    _stop               => \&client_stop,
    got_response        => \&client_got_response,
  },
  package_states => [main => [qw(
    testd_registered
    testd_client_input
    testd_disconnected
    timeout
  )]],
);

# Run it all until done.
$poe_kernel->run();

exit;
