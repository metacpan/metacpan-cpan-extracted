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
  skip "consul test environment not available", 17 unless $tc;

  my $loop = IO::Async::Loop->new;
  testing_loop($loop);

  my $kv = Net::Async::Consul->kv(loop => $loop, port => $tc->port);
  ok $kv, "got KV API object";

  {
    my $r;
    $kv->put(foo => "bar", cb => sub { ($r) = @_ });
    wait_for { $r };
    ok $r, "key was updated";
  }

  my $index = do {
    my ($r, $meta);
    $kv->get("foo", cb => sub { ($r, $meta) = @_ });
    wait_for { $r };
    is $r->value, "bar", "returned KV has correct value";
    isa_ok $meta, 'Consul::Meta', "got server meta object";
    $meta->index;
  };

  {
    my ($r1, $r2);
    $kv->get("foo", index => $index, cb => sub { ($r1) = @_ });
    $kv->put(foo => "baz",           cb => sub { ($r2) = @_ });
    wait_for { $r1 && $r2 };
    is $r1->value, "baz", "hey was updated";
    ok $r2, "watched KV updated to correct value";
  }
}

done_testing;
