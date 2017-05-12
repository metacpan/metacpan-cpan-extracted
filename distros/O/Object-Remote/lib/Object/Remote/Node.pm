package Object::Remote::Node;

use strictures 1;
use Object::Remote::Connector::STDIO;
use Object::Remote::Logging qw(:log :dlog);
use Object::Remote::WatchDog;
use Object::Remote;

sub run {
  my ($class, %args) = @_;
  log_trace { "run() has been invoked on remote node" };

  my $c = Object::Remote::Connector::STDIO->new->connect;

  $c->register_class_call_handler;

  my $loop = Object::Remote->current_loop;

  $c->on_close->on_ready(sub {
    log_debug { "Node connection with call handler has closed" };
    $loop->want_stop
  });

  Dlog_trace { "Node is sending 'Shere' to $_" } $c->send_to_fh;
  print { $c->send_to_fh } "Shere\n";

  log_debug { "Node is going to start the run loop" };
  #TODO the alarm should be reset after the run loop starts
  #at a minimum - the remote side node should probably send
  #a command that clears the alarm in all instances - even
  #if the Object::Remote::Watchdog is not being used
  if ($args{watchdog_timeout}) {
    Object::Remote::WatchDog->instance(timeout => $args{watchdog_timeout});
  } else {
    #reset connection watchdog from the fatnode
    alarm(0);
  }
  $loop->want_run;
  $loop->run_while_wanted;
  log_debug { "Run loop invocation in node has completed" };
}

1;
