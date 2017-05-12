#!/usr/bin/env perl

# Simplistic ROUTER; responds to commands from included 'dealer.pl' example

use v5.10;
use strictures 1;

my $endpt = $ARGV[0] || 'tcp://127.0.0.1:5600';

use POE;
use POEx::ZMQ;

POE::Session->create(
  inline_states => +{
    _start => sub {
      $_[HEAP]->{rtr} = POEx::ZMQ::Socket
        ->new(type => ZMQ_ROUTER)
        ->start
        ->bind($endpt);
      say "ROUTER listening on '$endpt' . . .";
    },

    zmq_recv_multipart => sub {
      my $parts = $_[ARG0];
      my $envelope = $parts->items_before(sub { $_ eq '' });
      my $body     = $parts->items_after(sub { $_ eq '' });
      my ($cmd, $id) = @$body;

      say "Received message '$cmd', ID '$id'";

      $_[HEAP]->{rtr}->send_multipart(
        [ $envelope->all, '', 'BAR', $id ]
      );
    },
  },
);

POE::Kernel->run
