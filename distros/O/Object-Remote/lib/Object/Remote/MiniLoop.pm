package Object::Remote::MiniLoop;

use IO::Select;
use Time::HiRes qw(time);
use Object::Remote::Logging qw( :log :dlog router );
use Moo;

BEGIN {
  router()->exclude_forwarding
}

# this is ro because we only actually set it using local in sub run
has is_running => (is => 'ro', clearer => 'stop');
#maximum duration that select() will block - undef means indefinite,
#0 means no blocking, otherwise maximum time in seconds
has block_duration => ( is => 'rw' );

has _read_watches => (is => 'ro', default => sub { {} });
has _read_select => (is => 'ro', default => sub { IO::Select->new });

has _write_watches => (is => 'ro', default => sub { {} });
has _write_select => (is => 'ro', default => sub { IO::Select->new });

has _timers => (is => 'ro', default => sub { [] });

sub watch_io {
  my ($self, %watch) = @_;
  my $fh = $watch{handle};
  Dlog_debug { "Adding IO watch for $_" } $fh;

  if (my $cb = $watch{on_read_ready}) {
    log_trace { "IO watcher is registering with select for reading" };
    $self->_read_select->add($fh);
    $self->_read_watches->{$fh} = $cb;
  }
  if (my $cb = $watch{on_write_ready}) {
    log_trace { "IO watcher is registering with select for writing" };
    $self->_write_select->add($fh);
    $self->_write_watches->{$fh} = $cb;
  }
  return;
}

sub unwatch_io {
  my ($self, %watch) = @_;
  my $fh = $watch{handle};
  Dlog_debug { "Removing IO watch for $_" } $fh;
  if ($watch{on_read_ready}) {
    log_trace { "IO watcher is removing read from select()" };
    $self->_read_select->remove($fh);
    delete $self->_read_watches->{$fh};
  }
  if ($watch{on_write_ready}) {
    log_trace { "IO watcher is removing write from select()" };
    $self->_write_select->remove($fh);
    delete $self->_write_watches->{$fh};
  }
  return;
}

sub _sort_timers {
  my ($self, @new) = @_;
  my $timers = $self->_timers;

  log_trace { "Sorting timers" };

  @{$timers} = sort { $a->[0] <=> $b->[0] } @{$timers}, @new;
  return;
}

sub watch_time {
  my ($self, %watch) = @_;
  my $at;

  Dlog_trace { "watch_time() invoked with $_" } \%watch;

  if (exists($watch{after})) {
    $at = time() + $watch{after};
  } elsif (exists($watch{at})) {
    $at = $watch{at};
  } else {
    die "watch_time requires after or at";
  }

  die "watch_time requires code" unless my $code = $watch{code};
  my $timers = $self->_timers;
  my $new = [ $at => $code ];
  $self->_sort_timers($new);
  log_debug { "Created new timer with id '$new' that expires at '$at'" };
  return "$new";
}

sub unwatch_time {
  my ($self, $id) = @_;
  log_trace { "Removing timer with id of '$id'" };
  @$_ = grep !($_ eq $id), @$_ for $self->_timers;
  return;
}

sub _next_timer_expires_delay {
  my ($self) = @_;
  my $timers = $self->_timers;
  my $delay_max = $self->block_duration;

  return $delay_max unless @$timers;
  my $duration = $timers->[0]->[0] - time;

  log_trace { "next timer fires in '$duration' seconds" };

  if ($duration < 0) {
    $duration = 0;
  } elsif (defined $delay_max && $duration > $delay_max) {
    $duration = $delay_max;
  }

  return $duration;
}

sub loop_once {
  my ($self) = @_;
  my $read = $self->_read_watches;
  my $write = $self->_write_watches;
  my $read_count = 0;
  my $write_count = 0;
  my @c = caller;
  my $wait_time = $self->_next_timer_expires_delay;
  log_trace {
    sprintf("Run loop: loop_once() has been invoked by $c[1]:$c[2] with read:%i write:%i select timeout:%s",
      scalar(keys(%$read)), scalar(keys(%$write)), defined $wait_time ? $wait_time : 'indefinite' )
  };
  my ($readable, $writeable) = IO::Select->select(
    $self->_read_select, $self->_write_select, undef, $wait_time
  );
  log_trace {
    my $readable_count = defined $readable ? scalar(@$readable) : 0;
    my $writable_count = defined $writeable ? scalar(@$writeable) : 0;
    "Run loop: select returned readable:$readable_count writeable:$writable_count";
  };
  # I would love to trap errors in the select call but IO::Select doesn't
  # differentiate between an error and a timeout.
  #   -- no, love, mst.

  log_trace { "Reading from ready filehandles" };
  foreach my $fh (@$readable) {
    next unless $read->{$fh};
    $read_count++;
    $read->{$fh}();
    #FIXME this is a rough workaround for race conditions that can cause deadlocks
    #under load
    last;
  }
  log_trace { "Writing to ready filehandles" };
  foreach my $fh (@$writeable) {
    next unless $write->{$fh};
    $write_count++;
    $write->{$fh}();
    #FIXME this is a rough workaround for race conditions that can cause deadlocks
    #under load
    last;
  }

  #moving the timers above the read() section exposes a deadlock
  log_trace { "Read from $read_count filehandles; wrote to $write_count filehandles" };
  my $timers = $self->_timers;
  my $now = time();
  log_trace { "Checking timers" };
  while (@$timers and $timers->[0][0] <= $now) {
    my $active = $timers->[0];
    Dlog_trace { "Found timer that needs to be executed: '$active'" };
    shift(@$timers);

    #execute the timer
    $active->[1]->();
  }

  log_trace { "Run loop: single loop is completed" };
  return;
}

sub run {
  my ($self) = @_;
  log_trace { "Run loop: run() invoked" };
  local $self->{is_running} = 1;
  while ($self->is_running) {
    $self->loop_once;
  }
  log_trace { "Run loop: run() completed" };
  return;
}

sub new_future {
    return Future->new;
}

our @await;

sub await {
  my ($self, $f) = @_;
  log_trace { my $ir = $f->is_ready; "await_future() invoked; is_ready: $ir" };
  return $f if $f->is_ready;
  require Object::Remote;
  my $loop = Object::Remote->current_loop;
  {
    local @await = (@await, $f);
    $f->on_ready(sub {
      log_trace { my $l = @await; "future has become ready, length of \@await: '$l'" };
      if ($f == $await[-1]) {
        log_trace { "This future is not waiting on anything so calling stop on the run loop" };
        $loop->stop;
      }
    });
    log_trace { "Starting run loop for newly created future" };
    $loop->run;
  }
  if (@await and $await[-1]->is_ready) {
    log_trace { "Last future in await list was ready, stopping run loop" };
    $loop->stop;
  }
  log_trace { "await_future() returning" };
  return $f;
}

sub await_all {
    my $self = shift;
    $self->await(Future->wait_all(@_));
    return;
}

1;
