#!/usr/bin/perl

# Test various error messages.

use warnings;
use strict;
use lib qw(./mylib ../mylib);
use Test::More tests => 12;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use POE;
use POE::Component::Client::Keepalive;
use POE::Component::Resolver;
use Socket qw(AF_INET);

sub test_err {
  my ($err, $target) = @_;
  $err =~ s/ at \S+ line \d+.*//s;
  ok($err eq $target, $target);
}

eval {
  my $x = POE::Component::Client::Keepalive->new("one parameter");
};
test_err($@, "new() needs an even number of parameters");

eval {
  my $x = POE::Component::Client::Keepalive->new(moo => 2);
};
test_err($@, "new() doesn't accept: moo");

my $cm = POE::Component::Client::Keepalive->new(
  resolver => POE::Component::Resolver->new(af_order => [ AF_INET ]),
);

eval {
  $cm->allocate("one parameter");
};
test_err($@, "allocate() needs an even number of parameters");

eval {
  $cm->allocate();
};
test_err($@, "allocate() needs a 'scheme'");

eval {
  $cm->allocate(
    scheme => "http",
  );
};
test_err($@, "allocate() needs an 'addr'");

eval {
  $cm->allocate(
    scheme => "http",
    addr   => "localhost",
  );
};
test_err($@, "allocate() needs a 'port'");

eval {
  $cm->allocate(
    scheme => "http",
    addr   => "localhost",
    port   => 80,
  );
};
test_err($@, "allocate() needs an 'event'");

eval {
  $cm->allocate(
    scheme => "http",
    addr   => "localhost",
    port   => 80,
    event  => "narf",
  );
};
test_err($@, "allocate() needs a 'context'");

eval {
  $cm->allocate(
    scheme  => "http",
    addr    => "localhost",
    port    => 80,
    event   => "narf",
    context => "moo",
    doodle  => "ha ha ha, die",
  );
};
test_err($@, "allocate() doesn't accept: doodle");

eval {
  $cm->free();
};
test_err($@, "can't free() undefined socket");

eval {
  $cm->free("not a socket");
};
test_err($@, "can't free() unallocated socket");

$cm->shutdown();

### Test the connection.

use TestServer;
my $server_port = TestServer->spawn(0);

POE::Session->create(
  inline_states => {
    _start => sub {
      my ($kernel, $heap) = @_[KERNEL, HEAP];
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
    },
    got_conn => sub {
      my ($kernel, $heap, $response) = @_[KERNEL, HEAP, ARG0];

      # Delete here to avoid an extra copy of the connection.
      my $conn = delete $response->{connection};

      eval {
        $conn->start("moo");
      };
      test_err($@, "Must call start() with an even number of parameters");

      # Free the connection.
      $conn = undef;

      TestServer->shutdown();
      $heap->{cm}->shutdown();
    },
    _child => sub { },
    _stop  => sub { },
  },
);

POE::Kernel->run();
