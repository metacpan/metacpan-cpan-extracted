#!/usr/bin/env perl
use strictures 1;
use feature 'say';

my $endpt = $ARGV[0] || 'tcp://127.0.0.1:5511';

use POE;
use POEx::ZMQ;

POE::Session->create(
  inline_states => +{
    _start => sub {
      # ->start returns the object; we can build and start in one go:
      $_[HEAP]->{sub} = POEx::ZMQ::Socket->new(type => ZMQ_SUB)->start;
      # ... then subscribe to the empty string to get all messages:
      $_[HEAP]->{sub}->set_sock_opt(ZMQ_SUBSCRIBE, '');
      # ... then ->connect and we're off:
      $_[HEAP]->{sub}->connect($endpt);
    },

    zmq_recv => sub {
      my $time = $_[ARG0];
      say "The time is $time";
    },
  },
);

POE::Kernel->run

