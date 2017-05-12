#!/usr/bin/env perl
use strictures 1;

my $endpt = $ARGV[0] || 'tcp://127.0.0.1:5511';

use POE;
use POEx::ZMQ;

POE::Session->create(
  inline_states => +{
    _start => sub {
      $_[HEAP]->{pub} = POEx::ZMQ::Socket->new(type => ZMQ_PUB)->start;
      $_[HEAP]->{pub}->bind($endpt);
      $_[KERNEL]->delay( publish => 1 );
    },

    publish => sub {
      my $ltime = localtime;
      my $utime = time;
      $_[HEAP]->{pub}->send("$ltime ($utime)");
      $_[KERNEL]->delay( publish => 1 );
    },
  },
);

POE::Kernel->run
