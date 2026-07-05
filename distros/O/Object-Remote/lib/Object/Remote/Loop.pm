package Object::Remote::Loop;

use Scalar::Util qw( refaddr weaken );
use Module::Runtime qw( use_module );
use Object::Remote::MiniLoop;
use Object::Remote::Logging qw( :log :dlog router );
use Moo;

BEGIN {
  $SIG{PIPE} = sub { log_debug { "Got a PIPE signal" } };

  router()->exclude_forwarding
}

has loop => (
  is => 'ro',
    default => sub {
      if ($ENV{OBJECT_REMOTE_LOOP}) {
        return use_module($ENV{OBJECT_REMOTE_LOOP})->new;
      }
      Object::Remote::MiniLoop->new
    });

has _timers => (is => 'ro', default => sub { {} });

for my $fn (qw( watch_io unwatch_io
                loop_once run stop await await_all
            )) {
  my $code = "sub ${fn} { my \$self = shift; \$self->loop->${fn}(\@_); }";
  eval $code;
}

sub want_run {
  my ($self) = @_;
  Dlog_debug { "Run loop: Incremeting want_running, is now $_" }
    ++$self->{want_running};
}

sub run_while_wanted {
  my ($self) = @_;
  log_debug { my $wr = $self->{want_running}; "Run loop: run_while_wanted() invoked; want_running: $wr" };
  $self->loop_once while $self->{want_running};
  log_debug { "Run loop: run_while_wanted() completed" };
  return;
}

sub want_stop {
  my ($self) = @_;
  if (! $self->{want_running}) {
    log_debug { "Run loop: want_stop() was called but want_running was not true" };
    return;
  }
  Dlog_debug { "Run loop: decrimenting want_running, is now $_" }
    --$self->{want_running};
}

sub new_future {
  return $_[0]->loop->new_future;
}

sub watch_time {
  my ($self, %watch) = @_;
  my ($code, $id);
  my $our_id;
  if (not ($watch{every} or $watch{after} or $watch{at})) {
    die "watch_time requires every, after or at";
  }
  elsif ($watch{every}) {
    $code = sub {
      $id = $self->loop->watch_time( %watch, code => $code );
      $watch{code}->(@_);
    };
    $watch{after} = delete $watch{every};
  }
  else {
    $code = sub {
      delete $self->_timers->{"$our_id"};
      $watch{code}->(@_);
    }
  }
  $our_id = refaddr $code;
  $self->_timers->{$our_id} = \$id;
  $id = $self->loop->watch_time( %watch, code => $code );
  weaken($code);
  return $our_id;
}

sub unwatch_time {
  my ($self, $id) = @_;
  my $timer = delete $self->_timers->{$id};
  if ($timer) {
    $self->loop->unwatch_time( ${$timer} )
  }
}

1;
