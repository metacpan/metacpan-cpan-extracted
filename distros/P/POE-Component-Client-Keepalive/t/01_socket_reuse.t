#!/usr/bin/perl
# vim: filetype=perl

# Test connection reuse.  Allocates a connection, frees it, and
# allocates another.  The second allocation should return right away
# because it is honored from the keep-alive pool.

use warnings;
use strict;
use lib qw(./mylib ../mylib);
use Test::More tests => 4;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use POE;
use POE::Component::Client::Keepalive;
use POE::Component::Resolver;
use Socket qw(AF_INET);

use TestServer;
my $server_port = TestServer->spawn(0);

POE::Session->create(
  inline_states => {
    _child   => sub { },
    _start   => \&start,
    _stop    => sub { },
    got_conn => \&got_conn,
  }
);

sub start {
  my $heap = $_[HEAP];

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
}

sub got_conn{
  my ($heap, $stuff) = @_[HEAP, ARG0];

  # The delete() ensures only one copy of the connection exists.
  my $connection = delete $stuff->{connection};
  my $which = $stuff->{context};

  if (defined $connection) {
    pass "$which request honored asynchronously";
  }
  else {
    fail(
      "$which request $stuff->{function} error $stuff->{error_num}: " .
      $stuff->{error_str}
    );
  }

  my $is_cached = $stuff->{from_cache};
  # Destroy the connection, freeing its socket.
  $connection = undef;

  if ($which eq 'first') {
    ok(not (defined ($is_cached)), "$which request not from cache");
    $heap->{cm}->allocate(
     scheme  => "http",
     addr    => "localhost",
     port    => $server_port,
     event   => "got_conn",
     context => "second",
    );
  } elsif ($which eq 'second') {
    ok(defined $is_cached, "$which request from cache");
    TestServer->shutdown();
		$heap->{cm}->shutdown();
  }

}

POE::Kernel->run();
exit;
