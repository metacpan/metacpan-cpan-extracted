package Object::Remote::WatchDog;

use Object::Remote::MiniLoop;
use Object::Remote::Logging qw (:log :dlog router);
use Moo;

has timeout => ( is => 'ro', required => 1 );

BEGIN { router()->exclude_forwarding; }

sub instance {
  my ($class, @args) = @_;

  return our $WATCHDOG ||= do {
    log_trace { "Constructing new instance of global watchdog" };
    $class->new(@args);
  };
};

#start the watchdog
sub BUILD {
  my ($self) = @_;

  $SIG{ALRM} = sub {
    #if the Watchdog is killing the process we don't want any chance of the
    #process not actually exiting and die could be caught by an eval which
    #doesn't do us any good
    log_fatal { "Watchdog has expired, terminating the process" };
    exit(1);
  };

  Dlog_debug { "Initializing watchdog with timeout of $_ seconds" } $self->timeout;
  alarm($self->timeout);
}

#invoke at least once per timeout to stop
#the watchdog from killing the process
sub reset {
  die "Attempt to reset the watchdog before it was constructed"
    unless defined our $WATCHDOG;

  log_debug { "Watchdog has been reset" };
  alarm($WATCHDOG->timeout);
}

#must explicitly call this method to stop the
#watchdog from killing the process - if the
#watchdog is lost because it goes out of scope
#it makes sense to still terminate the process
sub shutdown {
  my ($self) = @_;
  log_debug { "Watchdog is shutting down" };
  alarm(0);
}

1;


