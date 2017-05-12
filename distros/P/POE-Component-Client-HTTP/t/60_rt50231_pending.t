#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
  my @proxies = grep /^http.*proxy$/i, keys %ENV;
  delete @ENV{@proxies} if @proxies;
}

use POE qw(
  Filter::Stream
  Component::Client::HTTP
  Component::Client::Keepalive
);
use HTTP::Request::Common qw(GET);
use Test::More;
use Test::POE::Server::TCP;

plan tests => 2 * 3;

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

# limit parallelism to 1 request at a time
my $pool = POE::Component::Client::Keepalive->new(
    keep_alive   => 10,    # seconds to keep connections alive
    max_open     => 1,    # max concurrent connections - total
    max_per_host => 1,    # max concurrent connections - per host
    timeout      => 30,    # max time (seconds) to establish a new connection
);

my $http_alias = 'ua';

POE::Component::Client::HTTP->spawn(
    Alias             => $http_alias,
    Timeout           => 30,
    FollowRedirects   => 1,
    ConnectionManager => $pool,
);

POE::Session->create(
    inline_states => {
        _start    => \&_start,
        _response => \&_response,
        testd_registered => \&testd_reg,
        testd_client_input => \&testd_input,
    },
    heap => {
        pending_requests => 0,
    },
);

POE::Kernel->run;

sub _start {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    $_[HEAP]->{testd} = Test::POE::Server::TCP->spawn(
      filter => POE::Filter::Stream->new,
      address => 'localhost',
    );

    return;
}

sub testd_reg {
	my ($kernel) = $_[KERNEL];

	for ( 1 .. 2 ) {
		$kernel->post( $http_alias,
			request => '_response',
			GET( "http://localhost:" . $_[HEAP]->{testd}->port . "/test",
				Connection => 'close' ),
			$_,
		);

		$_[HEAP]->{pending_requests}++;
	}

	return;
}

sub testd_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];

  $heap->{input_buffer} .= $input;
  my $buffer = $heap->{input_buffer};

  if ($buffer =~ /^GET \/test/) {
    pass("got test request");
    $heap->{input_buffer} = "";
    $heap->{testd}->send_to_client($id, $data);
  }
  else {
    diag("INPUT: $input");
    diag("unexpected test");
  }
}

sub _response {
    my ( $heap, $kernel, $request_packet, $response_packet )
        = @_[ HEAP, KERNEL, ARG0, ARG1 ];

    $heap->{pending_requests}--;


    my $request  = $request_packet->[0];
    my $id       = $request_packet->[1];
    my $response = $response_packet->[0];

    my $ua_pending     = $kernel->call($http_alias => 'pending_requests_count');
    my $actual_pending = $heap->{pending_requests};
    cmp_ok( $ua_pending, '==', $actual_pending, "pending count matches reality for $id" );

    if ( $response->is_success ) {
        pass("got response data");
    }
    else {
        fail("got response data");
        diag( ' HTTP Error: '
            . $response->code . ' '
            . ( $response->message || '' ) );
    }

    # lets shut down if its the last response
    if ( $heap->{pending_requests} == 0 ) {
	$kernel->call( $http_alias => 'shutdown' );
	$heap->{testd}->shutdown;
    }

    return;
}

