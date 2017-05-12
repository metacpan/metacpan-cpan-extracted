#!/usr/bin/perl

# Test rapid connection reuse.  Sets the maximum overall connections
# to a low number.  Allocate up to the maximum.  Reuse one of the
# connections, and allocate a completely different connection.  The
# allocation shuld be deferred, and one of the free sockets in the
# keep-alive pool should be discarded to make room for it.

use warnings;
use strict;
use lib qw(./mylib ../mylib);
use Test::More tests => 7;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use POE;
use POE::Component::Client::Keepalive;
use POE::Component::Resolver;
use Socket qw(AF_INET);

use TestServer;

my $port_a = TestServer->spawn(0);
my $port_b = TestServer->spawn(0);

POE::Session->create(
  inline_states => {
    _child           => sub { },
    _start           => \&start,
    _stop            => sub { },
    got_another_conn => \&got_another_conn,
    got_conn         => \&got_conn,
    got_error        => \&got_error,
  }
);

sub start {
  my $heap = $_[HEAP];

  $heap->{cm} = POE::Component::Client::Keepalive->new(
    max_open => 2,
    resolver => POE::Component::Resolver->new(af_order => [ AF_INET ]),
  );

  $heap->{conn_count} = 0;

  {
    $heap->{cm}->allocate(
      scheme  => "http",
      addr    => "localhost",
      port    => $port_a,
      event   => "got_conn",
      context => "first",
    );
  }

  {
    $heap->{cm}->allocate(
      scheme  => "http",
      addr    => "localhost",
      port    => $port_a,
      event   => "got_conn",
      context => "second",
    );
  }
}

sub got_conn {
  my ($heap, $response) = @_[HEAP, ARG0];

  my $conn  = delete $response->{connection};
  my $which = $response->{context};

  if (defined $conn) {
    pass "$which request established asynchronously";
  }
  else {
    fail(
      "$which request $response->{function} error $response->{error_num}: " .
      $response->{error_str}
    );
  }

  ok(!defined($response->{from_cache}), "$which connection request deferred");

  $conn = undef;

  return unless ++$heap->{conn_count} == 2;

  # Re-allocate one of the connections.

  $heap->{cm}->allocate(
    scheme  => "http",
    addr    => "localhost",
    port    => $port_a,
    event   => "got_another_conn",
    context => "third",
  );


  $heap->{cm}->allocate(
    scheme  => "http",
    addr    => "localhost",
    port    => $port_b,
    event   => "got_another_conn",
    context => "fourth",
  );
}

sub got_another_conn {
  my ($heap, $response) = @_[HEAP, ARG0];

  # Deleting here to avoid a copy of the connection in %$response.
  my $conn  = delete $response->{connection};
  my $which = $response->{context};

  if ($which eq 'third') {
    is(
      $response->{from_cache}, 'immediate',
      "$which connection request honored from pool"
    );
    return;
  }

  if ($which eq 'fourth') {
    ok(
      !defined ($response->{from_cache}),
      "$which connection request honored from pool"
    );

    if (defined $conn) {
      pass "$which request established asynchronously";
    }
    else {
      fail(
        "$which request $response->{function} error $response->{error_num}: " .
        $response->{error_str}
      );
    }

    # Free the connection first.
    $conn = undef;

    TestServer->shutdown();
    $heap->{cm}->shutdown();
    return;
  }

  die;
}

POE::Kernel->run();
exit;
