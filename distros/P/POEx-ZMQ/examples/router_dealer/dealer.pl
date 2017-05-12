#!/usr/bin/env perl

# Simplistic DEALER; talks to included 'router.pl' example

use v5.10;
use strictures 1;

my $endpt = $ARGV[0] || 'tcp://127.0.0.1:5600';

use POE;
use POEx::ZMQ;

POE::Session->create(
  inline_states => +{
    _start => sub {
      $_[HEAP]->{dlr} = POEx::ZMQ::Socketi
        ->new(type => ZMQ_DEALER)
        ->start
        ->connect($endpt);

      $_[KERNEL]->delay( send_request => 1 );
      $_[KERNEL]->delay( timeout => 60 );

      say "DEALER connecting to '$endpt' . . . ";
    },

    send_request => sub {
      my $x = $_[ARG0] //= 0;
      $_[HEAP]->{dlr}->send_multipart( [ '', 'FOO', ++$x ] );
      $_[KERNEL]->delay( send_request => 1, $x );
    },

    zmq_recv_multipart => sub {
      $_[KERNEL]->delay( timeout => 30 );
      my $parts = $_[ARG0];
      my $envelope = $parts->items_before(sub { $_ eq '' });
      my $body     = $parts->items_after(sub { $_ eq '' });
      my ($cmd, $id) = @$body;
      say "Received reply '$cmd' to message ID '$id'";
    },

    timeout => sub {
      die "No reply from '$endpt' in 60s . . . \n";
    },
  },
);

POE::Kernel->run
