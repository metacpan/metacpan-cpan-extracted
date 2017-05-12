use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils;

use POE;
use POEx::ZMQ;


use File::Temp ();
my $tempdir = File::Temp::tempdir(CLEANUP => 1);
my $endpt   = "ipc://$tempdir/test-poex-ffi-$$";

my $Got = hash;
my $Expected = hash(
  # 100 messages, two subscribers:
  'subscriber got message' => 200,
);


alarm 60;

POE::Session->create(
  package_states => [
    main => [ qw/
      _start
      timeout

      check_if_done

      start_publishing

      zmq_recv
    / ],
  ],
);

sub _start {
  $_[KERNEL]->sig( ALRM => 'timeout' );
  $_[KERNEL]->yield( 'check_if_done' );
  
  my $zmq = POEx::ZMQ->new;
  $_[HEAP]->{zmq} = $zmq;

  $_[HEAP]->{pub}  = $zmq->socket( type => ZMQ_PUB )
    ->start
    ->bind($endpt);

  $_[HEAP]->{subX} = $zmq->socket( type => ZMQ_SUB )
    ->start
    ->connect($endpt)
    ->set_sock_opt(ZMQ_SUBSCRIBE, '');
  $_[HEAP]->{subY} = $zmq->socket( type => ZMQ_SUB )
    ->start
    ->connect($endpt)
    ->set_sock_opt(ZMQ_SUBSCRIBE, '');

  # delay publishing to wait for slow subscribers
  $_[KERNEL]->delay( start_publishing => 0.2 );
}

sub check_if_done {
  my $done = !! $Got->keys->count == $Expected->keys->count
    && $Got->{'subscriber got message'}
         == $Expected->{'subscriber got message'}
  ;

  if ($done) {
    $_[HEAP]->{$_}->stop for qw/subX subY pub/;
    $_[KERNEL]->alarm_remove_all;
  } else {
    $_[KERNEL]->delay_set( check_if_done => 0.2 );
  }
}

sub timeout {
  $_[KERNEL]->alarm_remove_all;
  fail "Timed out!"; diag explain $Got; exit 1
}

sub start_publishing {
  $_[HEAP]->{pub}->send( $_ ) for 1 .. 100;
}

sub zmq_recv {
  $Got->{'subscriber got message'}++;
}

POE::Kernel->run;

is_deeply $Got, $Expected, 'async pubsub tests ok'
  or diag explain $Got;

done_testing
