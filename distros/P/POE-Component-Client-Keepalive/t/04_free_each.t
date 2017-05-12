#!/usr/bin/perl

# Testing the bits that keep track of connections per connection key.

use warnings;
use strict;
use lib qw(./mylib ../mylib);
use Test::More tests => 6;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use POE;
use POE::Component::Client::Keepalive;
use POE::Component::Resolver;
use Socket qw(AF_INET);

use TestServer;
my $server_port = TestServer->spawn(0);

POE::Session->create(
  inline_states => {
    _start      => \&start,

    got_conn    => \&got_conn,
    got_error   => \&got_error,
    got_timeout => \&got_timeout,
    test_alloc  => \&test_alloc,
    and_free    => \&and_free,

    _child => sub { },
    _stop  => sub { },
  }
);

# Allocate two connections.  Wait for both to be allocated.  Free them
# both.

sub start {
  my $heap = $_[HEAP];

  $heap->{cm} = POE::Component::Client::Keepalive->new(
    resolver => POE::Component::Resolver->new(af_order => [ AF_INET ]),
  );

  {
    $heap->{cm}->allocate(
      scheme  => "http",
      addr    => "localhost",
      port    => $server_port,
      event   => "got_conn",
      context => "first",
    );
  }

  {
    $heap->{cm}->allocate(
      scheme  => "http",
      addr    => "localhost",
      port    => $server_port,
      event   => "got_conn",
      context => "second",
    );
  }
}

sub got_conn {
  my ($heap, $stuff) = @_[HEAP, ARG0];

  my $conn  = $stuff->{connection};
  my $which = $stuff->{context};

  ok(defined($conn), "$which connection created successfully");
  ok(not (defined ($stuff->{from_cache})), "$which not from cache");

  $heap->{conn}{$which} = $conn;

  return unless keys(%{$heap->{conn}}) == 2;

  # Shut this one down.
  $heap->{conn}{$which}->start();
  $heap->{conn}{$which}->wheel()->shutdown_input();
  $heap->{conn}{$which}->wheel()->shutdown_output();

  # Free all heaped connections.
  delete $heap->{conn};

  # Give the server time to accept the connection.
  $_[KERNEL]->delay(test_alloc => 1);
}

# Allocate and free a third connection.  It's reused from the free
# pool.

sub test_alloc {
  my $heap = $_[HEAP];

  $heap->{cm}->allocate(
    scheme  => "http",
    addr    => "localhost",
    port    => $server_port,
    event   => "and_free",
    context => "third",
  );
}

sub and_free {
  my ($heap, $stuff) = @_[HEAP, ARG0];

  my $conn  = delete $stuff->{connection};
  my $which = $stuff->{context};

  if (defined $conn) {
    pass "$which request honored asynchronously";
  }
  else {
    fail(
      "$which request $stuff->{function} error $stuff->{error_num}: " .
      $stuff->{error_str}
    );
  }

  is(
    $stuff->{from_cache}, 'immediate',
    "third connection honored from the pool"
  );

  # Free the connection first.
  # Close its internal socket before freeing.  This will ensure that
  # the connection manager can cope with such things.
  close $conn->[POE::Component::Connection::Keepalive::CK_SOCKET];
  $conn = undef;

  TestServer->shutdown();
  $heap->{cm}->shutdown();
}

POE::Kernel->run();
exit;
