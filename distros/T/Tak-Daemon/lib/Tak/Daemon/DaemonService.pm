package Tak::Daemon::DaemonService;

use POSIX;
use Log::Contextual ();
use Log::Contextual::SimpleLogger;
use Tak::Router;
use Moo;

with 'Tak::Role::Service';

has 'set_done_cb' => (is => 'rw');

has 'router' => (is => 'lazy');

sub _build_router { Tak::Router->new }

sub handle_daemonize {
  my ($self) = @_;
  fork and exit;
  POSIX::setsid or die "Couldn't setsid: $!";
  fork and exit;
  return 'done';
}

sub handle_become_successor {
  my ($self) = @_;
  my $done;
  $self->set_done_cb(sub { $done = 1 });
  # because this is funnier than "no warnings 'once'". Also because
  # I don't have to stop and think "what else is in this lexical scope?"
  $Tak::STDIOSetup::Next = $Tak::STDIOSetup::Next = sub {

    # have to do this here because when we're being set up stderr may
    # be redirected (e.g. because we're in an ->do under a repl) - and
    # plus it leaves logging running until the last possible minute,
    # which is almost certainly a win anyway.
    close STDERR;
    open STDERR, '>', '/dev/null' or die "Couldn't re-open stderr: $!";
    Log::Contextual::set_logger( # there's no NullLogger? I thought I wrote one
      Log::Contextual::SimpleLogger->new({ levels => [] })
    );

    my $x = $self; # close over while evading void context warnings
    $0 = 'tak-daemon-node';
    Tak->loop_until($done);
  };
  return 'done';
}

sub handle_shutdown {
  my ($self) = @_;
  $self->set_done_cb->();
  return 'done';
}

sub start_router_request {
  shift->router->start_request(@_);
}

sub receive_router {
  shift->router->receive(@_);
}

1;
