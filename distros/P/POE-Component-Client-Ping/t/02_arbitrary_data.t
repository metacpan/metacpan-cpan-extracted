#!/usr/bin/perl
# vim: filetype=perl

use strict;
use warnings;

BEGIN {
  $| = 1;
  if ($> and ($^O ne 'VMS')) {
    print "1..0 # skipped: ICMP ping requires root privilege\n";
    exit 0;
  }
};

sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use POE qw(Component::Client::Ping);
use Test::More tests => 1;

$|=1;

POE::Component::Client::Ping->spawn( Alias => 'pinger', OneReply => 1 );

POE::Session->create(
  package_states => [
    'main' => [ qw(_start pong) ],
  ],
  options => { trace => 0 },
);

POE::Kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->post( 'pinger', 'ping', [ 'pong', 'foo' ], "poe.perl.org" );
}

sub pong {
  my ($heap, $request, $response) = @_[HEAP, ARG0, ARG1];
  $request->[3] = "(undef)" unless defined $request->[3];
  ok($request->[3] eq "foo", "got arbitrary data: $request->[3]");
}

