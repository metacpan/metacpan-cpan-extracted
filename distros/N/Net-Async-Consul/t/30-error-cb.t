#!perl

use warnings;
use strict;

use Test::More;
use Test::Exception;

use IO::Async::Loop;
use IO::Async::Test;
use Net::Async::Consul;

my $loop = IO::Async::Loop->new;
testing_loop($loop);

{
  my $error;
  my $agent = Net::Async::Consul->agent(loop => $loop, error_cb => sub { $error =1 });
  ok $agent, "got Agent API object";

  lives_ok { $agent->members } "failing call with global error callback succeeds";
  wait_for sub { $error };
  ok $error, "global error callback was called";
}

{
  my $agent = Net::Async::Consul->agent(loop => $loop);
  ok $agent, "got Agent API object";

  my $error;
  lives_ok { $agent->members(error_cb => sub { $error = 1 }) } "failing call with error callback succeeds";
  wait_for sub { $error };
  ok $error, "error callback was called";
}

done_testing;
