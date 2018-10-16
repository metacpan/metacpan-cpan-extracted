#!perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Consul;

use IO::Async::Loop;
use IO::Async::Test;
use Net::Async::Consul;

my $tc = eval { Test::Consul->start };

SKIP: {
  skip "consul test environment not available", 4 unless $tc;

  my $loop = IO::Async::Loop->new;
  testing_loop($loop);

  my $kv = Net::Async::Consul->kv(loop => $loop, port => $tc->port);
  ok $kv, "got KV API object";

  {
    my ($r, $meta);
    $kv->put(foo => "bar", cb => sub { ($r, $meta) = @_ });
    wait_for { $r };
    ok $r, "key was updated";
  }

  {
    my ($r, $meta);
    $kv->get("foo", cb => sub { ($r, $meta) = @_ });
    wait_for { $r };
    is $r->value, "bar", "returned KV has correct value";
    isa_ok $meta, 'Consul::Meta', "got server meta object";
  }
}

done_testing;
