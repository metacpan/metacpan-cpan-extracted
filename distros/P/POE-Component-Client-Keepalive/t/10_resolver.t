#!/usr/bin/perl

# Test connection reuse.  Allocates a connection, frees it, and
# allocates another.  The second allocation should return right away
# because it is honored from the keep-alive pool.

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

my $test_server_use_count = 0;

POE::Session->create(
  inline_states => {
    _child   => sub { },
    _start   => \&start_with,
    _stop    => sub { },
    got_conn => \&got_conn,
  }
);

POE::Session->create(
  inline_states => {
    _child   => sub { },
    _start   => \&start_without,
    _stop    => sub { },
    got_conn => \&got_conn,
  }
);

sub start_with {
  my $heap = $_[HEAP];

  $_[KERNEL]->alias_set ('WITH');
  $heap->{cm} = POE::Component::Client::Keepalive->new(
    resolver => POE::Component::Resolver->new(af_order => [ AF_INET ]),
  );

  $heap->{cm}->allocate(
    scheme  => "http",
    addr    => "localhost",
    port    => $server_port,
    event   => "got_conn",
    context => "first",
  );

  ++$test_server_use_count;
}

sub start_without {
  my $heap = $_[HEAP];

  $_[KERNEL]->alias_set ('WITHOUT');
  $heap->{cm} = POE::Component::Client::Keepalive->new(
    resolver => POE::Component::Resolver->new(af_order => [ AF_INET ]),
  );

  $heap->{cm}->allocate(
    scheme  => "http",
    addr    => "localhost",
    port    => $server_port,
    event   => "got_conn",
    context => "second",
  );

  ++$test_server_use_count;
}

# TODO - I think this callback is polymorphic (first vs. second)
# bcause it has common code.  It's probably cleaner to implement two
# separate callbacks and some helpers to handle their commonalities.

sub got_conn{
  my ($kernel, $heap, $response) = @_[KERNEL, HEAP, ARG0];

  # The delete() ensures only one copy of the connection exists.
  my $connection = delete $response->{connection};
  my $which = $response->{context};

  if (defined $connection) {
    pass "$which request honored asynchronously";
  }
  else {
    fail(
      "$which request $response->{function} error $response->{error_num}: " .
      $response->{error_str}
    );
  }

  ok(
    (not defined $response->{'from_cache'}),
    "$which request not from cache"
  );

  if ($which eq 'first') {
    ok(1, "$which request from internal resolver");
  } elsif ($which eq 'second') {
    ok(1, "$which request from external resolver");
  }

  TestServer->shutdown() unless --$test_server_use_count;

  # need this so we don't get trace output about our session having
  # already died
  $connection = undef;
  # and this so we can terminate without having to go through the
  # idle polling period
  $heap->{cm}->shutdown;
  # and this so we terminate at all
  delete $heap->{cm};
}

POE::Kernel->run();
exit;
