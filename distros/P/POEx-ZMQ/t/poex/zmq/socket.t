use Test::More;
use strict; use warnings FATAL => 'all';

use Time::HiRes ();

use List::Objects::WithUtils;

use POE;
use POEx::ZMQ;


use File::Temp ();
my $tempdir = File::Temp::tempdir(CLEANUP => 1);
my $endpt = "ipc://$tempdir/test-poex-ffi-$$";


my $Got = hash;
my $Expected = hash(
  'got connect_added'     => 1,
  'got bind_added'        => 1,
  'rtr got 3 items'       => 1,
  'rtr got id'            => 1,
  'multipart body ok'     => 1,
  'single-part body ok'   => 1,
  'rtr got second msg'    => 1,
  'set hwm ok'            => 1,
  'get last_endpoint ok'  => 1,
  'context set/get ok'    => 1,
);


alarm 60;

POE::Session->create(
  package_states => [
    main => [ qw/
      _start
      timeout

      check_if_done

      router_req_setup

      test_get_set

      zmq_connect_added
      zmq_bind_added

      zmq_recv
      zmq_recv_multipart
    / ],
  ],
);

sub check_if_done {
  if ($Got->keys->count == $Expected->keys->count) {
    diag "Matching key counts, exiting loop";
    $_[HEAP]->{$_}->stop for qw/rtr req/;
    $_[KERNEL]->alarm_remove_all;
  } else {
    $_[KERNEL]->delay_set( check_if_done => 0.2 );
  }
}

sub _start {
  $_[KERNEL]->sig( ALRM => 'timeout' );
  $_[KERNEL]->yield('check_if_done');

  $_[HEAP]->{ctx} = POEx::ZMQ->context;

  $_[HEAP]->{rtr} = POEx::ZMQ::Socket->new(
    context => $_[HEAP]->{ctx},
    type    => ZMQ_ROUTER,
  )->start;

  $_[HEAP]->{req} = POEx::ZMQ::Socket->new(
    context => $_[HEAP]->{ctx},
    type    => ZMQ_REQ,
  )->start;

  ok $_[HEAP]->{req}->type == ZMQ_REQ, 'type attr ok';
  ok $_[HEAP]->{req}->zmq_version->string, 'zmq_version ok';
  isa_ok $_[HEAP]->{req}->zsock, 'POEx::ZMQ::FFI::Socket';
  isa_ok $_[HEAP]->{req}->context, 'POEx::ZMQ::FFI::Context';
  
  $_[KERNEL]->yield( 'router_req_setup' );
  $_[KERNEL]->yield( 'test_get_set' );
}

sub router_req_setup {
  diag "Issuing connect, bind";

  $_[HEAP]->{req}->connect($endpt);

  $_[HEAP]->{rtr}->bind($endpt);

  $_[HEAP]->{req}->yield(
    sub { 
      diag "Issuing send"; 
      $_[OBJECT]->send( 'foo' ) 
    }
  );
}

sub test_get_set {
  # int
  diag "Testing set/get";
  $_[HEAP]->{rtr}->set_socket_opt( ZMQ_SNDHWM, 2000 );
  my $val = $_[HEAP]->{rtr}->get_socket_opt( ZMQ_SNDHWM );
  $Got->set('set hwm ok' => 1) if $val == 2000;

  # string
  my $lastendpt = $_[HEAP]->{req}->get_socket_opt( ZMQ_LAST_ENDPOINT );
  $Got->set('get last_endpoint ok' => 1) if $lastendpt eq $endpt;

  # context opts
  $_[HEAP]->{req}->set_context_opt( ZMQ_IO_THREADS, 2 );
  my $iothreads = $_[HEAP]->{req}->get_context_opt( ZMQ_IO_THREADS );
  $Got->set('context set/get ok' => 1) if $iothreads == 2;
  $_[HEAP]->{req}->set_context_opt( ZMQ_IO_THREADS, 1 );
}

sub zmq_connect_added {
  diag "Got connect_added";

  $Got->set('got connect_added' => 1) if $_[ARG0] eq $endpt;
}

sub zmq_bind_added {
  diag "Got bind_added";
  $Got->set('got bind_added' => 1) if $_[ARG0] eq $endpt;
}

my $done = 0;
sub zmq_recv {
  diag "Got recv";

  my $msg = $_[ARG0];

  $Got->set('single-part body ok' => 1) if $msg eq 'bar';

  $_[KERNEL]->post( $_[SENDER], send => 'bar' ) unless $done++;
}

sub zmq_recv_multipart {
  my $parts = $_[ARG0];

  diag "Got recv_multipart";

  $Got->set('rtr got 3 items' => 1) if $parts->count == 3;

  my $route = $parts->items_before(sub { $_ eq '' });
  my $content = $parts->items_after(sub { $_ eq '' });
  $Got->set('rtr got id' => 1) if $route->has_any;
  $Got->set('multipart body ok' => 1) if $content->head eq 'foo';
  $Got->set('rtr got second msg' => 1) if $content->head eq 'bar';

  # send_multipart (+ test from posted send)
  $_[KERNEL]->post( $_[SENDER], send_multipart =>
    [ $route->all, '', 'bar' ]
  );
}


sub timeout {
  $_[KERNEL]->alarm_remove_all;
  fail "Timed out!"; diag explain $Got; exit 1
}

POE::Kernel->run;

is_deeply $Got, $Expected, 'async socket tests ok'
  or diag explain $Got;

done_testing
