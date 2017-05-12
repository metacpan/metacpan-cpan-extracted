package Parallel::Fork::BossWorkerAsync;
use strict;
use warnings;
use Carp;
use Data::Dumper qw( Dumper );
use Socket       qw( AF_UNIX SOCK_STREAM PF_UNSPEC );
use Fcntl        qw( F_GETFL F_SETFL O_NONBLOCK );
use POSIX        qw( EINTR EWOULDBLOCK );
use IO::Select ();

our @ISA = qw();
our $VERSION = '0.09';

# TO DO (wish list):
# Restart crashed child workers.

# -----------------------------------------------------------------
sub new {
  my ($class, %attrs)=@_;
  my $self = {
    work_handler    => $attrs{work_handler},                # required
    init_handler    => $attrs{init_handler}   || undef,     # optional
    exit_handler    => $attrs{exit_handler}   || undef,     # optional
    result_handler  => $attrs{result_handler} || undef,     # optional
    worker_count    => $attrs{worker_count}   || 3,         # optional, how many child workers
    global_timeout  => $attrs{global_timeout} || 0,         # optional, in seconds, 0 is unlimited
    msg_delimiter   => $attrs{msg_delimiter}  || "\0\0\0",  # optional, may not appear in data
    read_size       => $attrs{read_size}      || 1024*1024, # optional, defaults to 1 MB
    verbose         => $attrs{verbose}        || 0,         # optional, *undocumented*, 0=silence, 1=debug
    shutting_down   => 0,
    force_down      => 0,
    pending         => 0,
    result_stream   => '',
    result_queue    => [],
    job_queue       => [],
  };
  bless($self, ref($class) || $class);

  croak("Parameter 'work_handler' is required") if ! defined($self->{work_handler});

  # Start the "boss" process, which will start the workers
  $self->start_boss();

  return $self;
}

# -----------------------------------------------------------------
sub serialize {
  my ($self, $ref)=@_;
  local $Data::Dumper::Deepcopy = 1;
  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Purity = 1;
  return Dumper($ref) . $self->{msg_delimiter};
}

# -----------------------------------------------------------------
sub deserialize {
  my ($self, $data)=@_;
  $data = substr($data, 0, - length($self->{msg_delimiter}));
  my $VAR1;
  my $ref = eval($data);
  if ($@) {
    confess("failed to deserialize: $@");
  }
  return $ref;  
}

# -----------------------------------------------------------------
# Pass one or more hashrefs for the jobs.
# Main app sends jobs to Boss.
sub add_work {
  my ($self, @jobs)=@_;
  $self->blocking($self->{boss_socket}, 1);
  while (@jobs) {
    $self->log("add_work: adding job to queue\n");
    my $job = shift(@jobs);
    my $n = syswrite( $self->{boss_socket}, $self->serialize($job) );
    croak("add_work: app write to boss: syswrite: $!") if ! defined($n);
    $self->{pending} ++;
    $self->log("add_work: job added to queue, $self->{pending} pending\n");
  }
}

# -----------------------------------------------------------------
# Syntactic nicety
sub get_result_nb {
  my ($self)=@_;
  return $self->get_result(blocking => 0);
}

# -----------------------------------------------------------------
# Main app gets a complete, single result from Boss.
# If defined, result_handler fires here.
# Return is result of work_handler, or result_handler (if defined),
# or {} (empty hash ref).
# Undef is returned if socket marked nonblocking and read would have
# blocked.
sub get_result {
  my ($self, %args)=@_;
  $args{blocking} = 1 if ! defined($args{blocking});
  carp("get_result() when no results pending") if ! $self->pending();

  my $rq_count = scalar(@{ $self->{result_queue} });  
  $self->log("get_result: $self->{pending} jobs in process, $rq_count results ready\n");

  if ( ! @{ $self->{result_queue} }) {
    $self->blocking($self->{boss_socket}, $args{blocking});
    $self->read($self->{boss_socket}, $self->{result_queue}, \$self->{result_stream}, 'app');
  
    # Handle nonblocking case
    if ( ! $args{blocking}  &&  ! @{ $self->{result_queue} }) {
      return undef;
    }
  }

  $self->log("get_result: got result\n");

  $self->{pending} --;
  if ($self->{pending} == 0  &&  $self->{shutting_down}) {
    $self->log("get_result: no jobs pending; closing boss\n");
    close($self->{boss_socket});
  }
  my $ref = $self->deserialize( shift( @{ $self->{result_queue} } ) );
  my $retval = $self->{result_handler} ? $self->{result_handler}->($ref) : $ref;
  $retval = {} if ! defined($retval);
  return $retval;
}

# -----------------------------------------------------------------
# Main app calls to see if there are submitted jobs for which no
# response has been collected.  It doesn't mean the responses are
# ready yet.
sub pending {
  my ($self)=@_;
  return $self->{pending};
}

# -----------------------------------------------------------------
# App tells boss to shut down by half-close.
# Boss then finishes work in progress, and eventually tells
# workers to exit.
# Boss sends all results back to app before exiting itself.
# Note: Boss won't be able to close cleanly if app ignores
# final reads...
# args: force => 0,1  defaults to 0
sub shut_down {
  my ($self, %args)=@_;
  $args{force} ||= 0;
  $self->{shutting_down} = 1;

  $self->log("shut_down: MARK\n");

  if ($args{force}) {
    # kill boss pid
    kill(9, $self->{boss_pid});
  } elsif ($self->pending()) {
    shutdown($self->{boss_socket}, 1);
  } else {
    close($self->{boss_socket});
  }

  while (wait() != -1) {};		# waits/reaps Boss process
}

# -----------------------------------------------------------------
# Make socket blocking/nonblocking
sub blocking {
  my ($self, $socket, $makeblocking)=@_;

  ### --- W I N D O W S --- ###
  if ($^O eq 'MSWin32') {
    # ioctl() requires a pointer to a long, containing the nonblocking value.

    # The long var
    my $nonblocking = pack('L', $makeblocking ? 0 : 1);

    # The pointer to it
    my $plong = unpack('I', pack('P', $nonblocking));

    # The nonblocking request. FIONBIO is 0x8004667e
    ioctl($socket, 0x8004667e, $plong)
      or croak("ioctl failed: $!");
  

  ### --- LINUX, BSD, etc --- ###
  } else {
    my $flags = fcntl($socket, F_GETFL, 0)
      or croak("fcntl failed: $!");
    my $blocking = ($flags & O_NONBLOCK) == 0;
    if ($blocking  && ! $makeblocking) {
      $flags |= O_NONBLOCK;
    } elsif (! $blocking && $makeblocking) {
      $flags &= ~O_NONBLOCK;
    } else {
      # do nothing
      return;
    }

    fcntl($socket, F_SETFL, $flags)
      or croak("fcntl failed: $!");
  }

  return;
}

# -----------------------------------------------------------------
sub start_boss {
  my ($self)=@_;
  $self->log("start_boss: start\n");
  eval {
    my ($b1, $b2);
    socketpair($b1, $b2, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
      or die("socketpair: $!");

    my $pid = fork();
    defined $pid || confess("fork failed: $!");

    if ($pid) {
      # Application (parent)
      $self->{boss_pid} = $pid;

      # App won't write to, or read from itself.
      close($b2);
      $self->{boss_socket} = $b1;

      $self->log("start_boss: Application: Boss started\n");

    } else {
      # Manager aka Boss (child)
      # Boss won't write to, or read from itself.
      close($b1);
      
      $self->{app_socket} = $b2;
      
      # Make nonblocking
      $self->blocking( $self->{app_socket}, 0 );
      open(STDIN, '/dev/null');
      
      $self->start_workers();
      $self->boss_loop();
      while (wait() != -1) {};			# waits/reaps workers only

      $self->log("start_boss: Boss: exiting\n");
      exit;
    }
  };
  if ($@) {
    croak($@);
  }
}

# -----------------------------------------------------------------
sub start_workers {
  my ($self)=@_;
  $self->log("start_workers: starting $self->{worker_count} workers\n");
  eval {
    for (1 .. $self->{worker_count}) {
      my ($w1, $w2);
      socketpair($w1, $w2, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die("socketpair: $!");
      
      my $pid = fork();
      defined $pid || confess("fork failed: $!");

      if ($pid) {
        # Boss (parent)
        close($w2);
        $self->{workers}->{ $w1 } = { pid => $pid, socket => $w1 };

        # Make nonblocking
        $self->blocking( $w1, 0 );
        
      } else {
        # Worker (child)
        close($self->{app_socket});
        delete($self->{workers});
        close($w1);
        $self->{socket} = $w2;
        open(STDIN, '/dev/null');
      
        $self->worker_loop();
        exit;
      }
    }

    $self->log("start_workers: start workers complete\n");
  };
  if ($@) {
    croak($@);
  }
}

# -----------------------------------------------------------------
# Boss process; have an open socket to the app, and one to each worker.
# Loop select(), checking for read and write on app socket, and read
# on working children, and write on idle children.
# Keep track of idle vs. working children.
# When receive a shutdown order from the app, keep looping until the
# job queue is empty, and all results have been retrieved (all
# children will now be idle.)  Then close the worker sockets.
# They'll be reading, and will notice this and exit.
# Don't deserialize any data.  Just look for the delimiters to know
# we're processing whole records.
#

sub boss_loop {
  my ($self)=@_;

  $self->log("boss_loop: start\n");
  eval {
    # handy
    my $workers = $self->{workers};
    
    # All workers start out idle
    for my $s (keys(%$workers)) {
      $workers->{ $s }->{idle} = 1;
    }
    
    while ( 1 ) {
      # When to exit loop?
      #   shutting_down = 1
      #   job_queue empty
      #   all workers idle, and no partial jobs
      #   result_queue empty
      if ($self->{shutting_down}  &&
          ! @{ $self->{job_queue} }  &&
          ! @{ $self->{result_queue} } ) {
        my $busy=0;
        my $partials = 0;
        for my $s (keys(%$workers)) {
          if ( ! $workers->{ $s }->{idle}) {
            $busy ++;
            last;
          } elsif (exists($workers->{ $s }->{partial_job})) {
            $partials ++;
            last;
          }
        }
        if ( ! $busy  &&  ! $partials) {
          # Close all workers
          for my $s (keys(%$workers)) {
            close($workers->{ $s }->{socket});
          }
          close($self->{app_socket});
          last;
        }
      }
      
      # Set up selectors:
      # Always check app for read, unless shutting down.  App write only if
      # there's something in @result_queue.
      my (@rpids, @wpids);
      my $rs = IO::Select->new();
      if ( ! $self->{shutting_down}) {
        $rs->add($self->{app_socket});
        push(@rpids, "app");
      }
      my $ws = IO::Select->new();
      if ( @{ $self->{result_queue} } ) {
        $ws->add($self->{app_socket});
        push(@wpids, "app");
      }
      
      # Check workers for read only if not idle
      # Otherwise, IF job_queue isn't empty,
      # check nonidle workers for write.
      for my $s (keys(%$workers)) {
        if ( $workers->{ $s }->{idle}) {
          if ( @{ $self->{job_queue} }  ||  exists($workers->{ $s }->{partial_job})) {
            $ws->add($workers->{ $s }->{socket});
            push(@wpids, $workers->{ $s }->{pid});
          }
        } else {
          $rs->add($workers->{ $s }->{socket});
          push(@rpids, $workers->{ $s }->{pid});
        }
      }
      
      # Blocking
      my @rdy = IO::Select->select($rs, $ws, undef);
      if ( ! @rdy) {
        if ($! == EINTR) {
          # signal interrupt, continue waiting
          next;
        }
        croak("select failed: $!");
      }
      my ($r, $w) = @rdy[0,1];
      
      # Now we have zero or more reabable sockets, and
      # zero or more writable sockets, but there's at
      # least one socket among the two groups.
      # Read first, as things read can be further handled
      # by writables immediately afterwards.
      
      for my $rh (@$r) {
        my ($source, $queue, $rstream);
        if ($rh != $self->{app_socket}) {
          $source = $workers->{$rh}->{pid};
          $queue = $self->{result_queue};
          $rstream = \$workers->{$rh}->{result_stream};
        } else {
          $source = 'app';
          $queue = $self->{job_queue};
          $rstream = \$self->{job_stream};
        }

        $self->log("boss_loop: reading socket\n");        
        $self->read($rh, $queue, $rstream, 'boss');
        $self->log("boss_loop: read socket complete\n");
      }

      for my $wh (@$w) {
        my $source = exists($workers->{ $wh }) ? $workers->{ $wh }->{pid} : "app";
        $self->log("boss_loop: writing socket\n");
        $self->write($wh);
        $self->log("boss_loop: write socket complete\n");
      }
    }
  };
  if ($@) {
    croak($@);
  }
}

# -----------------------------------------------------------------
sub write {
  my ($self, $socket)=@_;
  if ($socket == $self->{app_socket}) {
    $self->write_app($socket);
  } else {
    $self->write_worker($socket);
  }
}

# -----------------------------------------------------------------
sub write_app {
  my ($self, $socket)=@_;
  
  # App socket: write all bytes until would block, or complete.
  # This means process result_queue in order, doing as many elems
  # as possible.  Don't remove from the queue until complete.  In
  # other words, the first item on the queue may be a partial from
  # the previous write attempt.
  my $queue = $self->{result_queue};
  while (@$queue) {
    $self->log("write_app: processing queue entry\n");
    while ( $queue->[0] ) {
      my $n = syswrite($socket, $queue->[0]);
      if ( ! defined($n)) {
        # Block or real socket error
        if ($! == EWOULDBLOCK) {
          # That's it for this socket, try another, or select again.
          return;
        } else {
          croak("boss write to app: syswrite: $!");
        }
      }
        
      elsif ($n == 0) {
        # Application error: socket has been closed prematurely by other party.
        # Boss is supposed to close app socket before app.  App tells Boss to
        # stop, but it only happens after all existing work is completed, and
        # data is sent back to app.
        croak("boss write to app: peer closed prematurely");
          
      } else {
        # wrote some bytes, remove them from the queue elem
        substr($queue->[0], 0, $n) = '';
      }
    }
    # queue elem is empty, remove it, go try next one
    $self->log("write_app: process queue entry complete\n");
    shift(@$queue);
  }
  $self->log("write_app: all queue entries have been written\n");
  # queue is empty, all written!
}
 
# -----------------------------------------------------------------
sub write_worker {
  my ($self, $socket)=@_;
   
  # A worker: check to see if we have a remaining partial
  # job we already started to send.  If so, continue with this.
  # Otherwise, take a *single* job off the job_queue, and send that.
  # When we've gotten either complete, or would block, write remaining
  # portion to per-worker job-in-progress, or make it '' if complete.
  # With worker, we only send ONE job, never more.
  # Once job send is complete, mark worker not-idle.
  
  if ( ! exists($self->{workers}->{ $socket }->{partial_job})) {
    $self->log("write_worker: processing new job\n");
    if (@{ $self->{job_queue} }) {
      $self->{workers}->{ $socket }->{partial_job} = shift(@{ $self->{job_queue} });
    } else {
      # Nothing left on queue.  Remember, we select on *all* idle workers,
      # even if there's only one job on the queue.
      return;
    }
  } else {
    $self->log("write_worker: processing job remnant\n");
  }
  my $rjob = \$self->{workers}->{ $socket }->{partial_job};
  
  while ( length($$rjob) ) {
    $self->log("write_worker: writing...\n");
    my $n = syswrite($socket, $$rjob);
    if ( ! defined($n)) {
      # Block or real socket error
      if ($! == EWOULDBLOCK) {
        # That's it for this socket, try another, or select again.
        return;
      } else {
        croak("boss write to worker: syswrite: $!");
      }
    }
        
    elsif ($n == 0) {
      # Application error: socket has been closed prematurely by other party.
      # Boss is supposed to close worker socket before worker - that's how
      # worker knows to exit.
      croak("boss write to worker: peer closed prematurely (pid " . $self->{workers}->{ $socket }->{pid} . ")");
          
    } else {
      # wrote some bytes, remove them from the job
      substr($$rjob, 0, $n) = '';
      $self->log("write_worker: wrote $n bytes\n");
    }
  }
  # job all written!
  $self->log("write_worker: job complete\n");
  delete($self->{workers}->{ $socket }->{partial_job});
  $self->{workers}->{ $socket }->{idle} = 0;
}

# -----------------------------------------------------------------
# Boss exits loop on error, wouldblock, or shutdown msg (socket close).
# Worker exits loop on error, recd full record, or boss socket close.
# App exits loop on error, recd full record, wouldblock (nb only), early boss close (error).
# Stream (as external ref) isn't needed for worker, as it's blocking, and only reads a single
# record, no more.
# So $rstream can be undef, and if so, we init locally.
sub read {
  my ($self, $socket, $queue, $rstream, $iam)=@_;
  my $stream;
  $rstream = \$stream if ! defined($rstream);
  $$rstream = '' if ! defined($$rstream);

  # croak messaging details...
  my $source;
  if ($iam eq 'boss') {
    if ($socket == $self->{app_socket}) {
      $source = 'app';
    } else {
      $source = "worker [$self->{workers}->{$socket}->{pid}]";
    }
  } else {    # app or worker, same source
    $source = "boss";
  }

  while ( 1 ) {
    $self->log("read: $iam is reading...\n");

    my $n = sysread($socket, $$rstream, $self->{read_size}, length($$rstream));
    if ( ! defined($n)) {
      if ($! == EINTR) {
        # signal interrupt, continue reading
        next;
      } elsif ($! == EWOULDBLOCK) {
        last;    # No bytes recd, no need to chunk.
      } else {
        croak("$iam read from $source: sysread: $!");
      }
          
    } elsif ($n == 0) {
      # Application error: socket has been closed prematurely by other party.
      # Boss is supposed to close worker socket before worker - that's how
      # worker knows to exit.
      # Boss is supposed to close app socket before app.  App tells Boss to
      # stop, but it only happens after all existing work is completed, and
      # data is sent back to app.
      if ($iam eq 'boss') {
        if ($socket == $self->{app_socket}) {
          $self->{shutting_down} = 1;
        } elsif (exists($self->{workers}->{$socket})) {
          croak("$iam read from $source: peer closed prematurely (pid " . $self->{workers}->{ $socket }->{pid} . ")");
        }
      } elsif ($iam eq 'worker') {
        close($socket);
      } else {    # i am app
        croak("$iam read from $source: peer closed prematurely (pid " . $self->{boss_pid} . ")");
      }

      # if we didn't croak...
      last;
      
    } else {
      # We actually read some bytes.  See if we can chunk
      # out any record(s).
      $self->log("read: $iam read $n bytes\n");
      
      # Split on delimiter
      my @records = split(/(?<=$self->{msg_delimiter})/, $$rstream);

      # All but last elem are full records
      my $rcount=$#records;
      push(@$queue, @records[0..$#records-1]);

      # Deal with last elem, which may or may not be full record
      if ($records[ $#records ] =~ /$self->{msg_delimiter}$/) {
        # We have a full record
        $rcount++;
        $self->log("read: $iam pushing full record onto queue\n");
        push(@$queue, $records[ $#records ]);
        $$rstream = '';
        if (exists($self->{workers}->{ $socket })) {
          $self->{workers}->{ $socket }->{idle} = 1;
        }
      } else {
        $$rstream = $records[$#records];
      }

      # Boss grabs all it can get, only exiting loop on wouldblock.
      # App (even nb method), and workers all exit when one full
      # record is received.
      last if $rcount  &&  $iam ne 'boss';
    }
  }
}

# -----------------------------------------------------------------
# Worker process; single blocking socket open to boss.
# Blocking select loop:
# Only do read OR write, not both.  We never want more than a single
# job at a time.  So, if no job currently, read, waiting for one.
# Get a job, perform it, and try to write results.
# Send delimiter, which tells boss it has all the results, and we're ready
# for another job.
#
sub worker_loop {
  my ($self)=@_;
  eval {
    if ($self->{init_handler}) {
      $self->log("worker_loop: calling init_handler()\n");
      $self->{init_handler}->();
    }

    # String buffers to store serialized data: in and out.
    my $result_stream;
    while ( 1 ) {
      if (defined($result_stream)) {
        # We have a result: write it to boss
        $self->log("worker_loop: writing result...\n");
        
        my $n = syswrite( $self->{socket}, $result_stream);
        croak("worker [$$] write to boss: syswrite: $!") if ! defined($n);
        $self->log("worker_loop: wrote $n bytes\n")       if defined($n);
        $result_stream = undef;
        # will return to top of loop
        
      } else {
        # Get job from boss
        
        my @queue;
        $self->log("worker_loop: reading job from queue...\n");
        $self->read($self->{socket}, \@queue, undef, 'worker');
        return if ! @queue;
        $self->log("worker_loop: read job complete, we have a job\n");

        my $job = $self->deserialize($queue[0]);
        my $result;
        eval {
          local $SIG{ALRM} = sub {
            die("BossWorkerAsync: timed out");
          };

          # Set alarm
          alarm($self->{global_timeout});

          # Invoke handler and get result
          $self->log("worker_loop: calling work_handler for this job\n");
          $result = $self->{work_handler}->($job);

          # Disable alarm
          alarm(0);
        };

        if ($@) {
          $result = {ERROR => $@};
          $self->log("worker_loop: ERROR: $@\n");
        }
        
        $result_stream = $self->serialize($result);
      }
    }
  };
  my $errm = $@ || '';
  eval {
  if ($self->{exit_handler}) {
    $self->log("worker_loop: calling exit_handler()\n");
    $self->{exit_handler}->();
  }
  };
  $errm .= "\n$@" if $@;
  if ($errm) {
    croak($errm);
  }
}


# -----------------------------------------------------------------
# IN: log message
# If verbose is enabled, print the message.
sub log {
  my ($self, $msg) = @_;
  print STDERR $msg   if $self->{verbose};
}


1;
__END__

=head1 NAME

Parallel::Fork::BossWorkerAsync - Perl extension for creating asynchronous forking queue processing applications.

=head1 SYNOPSIS

  use Parallel::Fork::BossWorkerAsync ();
  my $bw = Parallel::Fork::BossWorkerAsync->new(
    work_handler    => \&work,
    result_handler  => \&handle_result,
    global_timeout  => 2,
  );

  # Jobs are hashrefs
  $bw->add_work( {a => 3, b => 4} );
  while ($bw->pending()) {
    my $ref = $bw->get_result();
    if ($ref->{ERROR}) {
      print STDERR $ref->{ERROR};
    } else {
      print "$ref->{product}\n";
      print "$ref->{string}\n";
    }
  }
  $bw->shut_down();

  sub work {
    my ($job)=@_;

    # Uncomment to test timeout
    # sleep(3);
    
    # Uncomment to test worker error
    # die("rattle");
    
    # do something with hash ref $job
    my $c = $job->{a} * $job->{b};

    
    # Return values are hashrefs
    return { product => $c };
  }

  sub handle_result {
    my ($result)=@_;
    if (exists($result->{product})) {
      $result->{string} = "the answer is: $result->{product}";
    }
    return $result;
  }

  __END__
  Prints:
  12
  the answer is: 12

=head1 DESCRIPTION

Parallel::Fork::BossWorkerAsync is a multiprocess preforking server.  On construction, the current process forks a "Boss" process (the server), which then forks one or more "Worker" processes.  The Boss acts as a manager, accepting jobs from the main process, queueing and passing them to the next available idle Worker.  The Boss then listens for, and collects any responses from the Workers as they complete jobs, queueing them for the main process.

The main process can collect available responses from the Boss, and/or send it more jobs, at any time. While waiting for jobs to complete, the main process can enter a blocking wait loop, or do something else altogether, opting to check back later.

In general, it's a good idea to construct the object early in a program's life, before any threads are spawned, and before much memory is allocated, as the Boss, and each Worker will inherit the memory footprint.

The 0.09 release includes Windows compatibility! (see Credits below)

=head1 METHODS

=head2 new(...)

Creates and returns a new Parallel::Fork::BossWorkerAsync object.

  my $bw = Parallel::Fork::BossWorkerAsync->new(
    work_handler    => \&work_sub,
    result_handler  => \&result_sub,
    init_handler    => \&init_sub,
    exit_handler    => \&exit_sub,
    global_timeout  => 0,
    worker_count    => 3,
    msg_delimiter   => "\0\0\0",
    read_size       => 1024 * 1024,
  );

=over 4

=item * C<< work_handler => \&work_sub >>
  
work_handler is the only required argument.  The sub is called with it's first and only argument being one of the values (hashrefs) in the work queue. Each worker calls this sub each time it receives work from the boss process. The handler may trap $SIG{ALRM}, which may be called if global_timeout is specified.

The work_handler should clean up after itself, as the workers may call the work_handler more than once.

The work_handler is expected to return a hashref.

=item * C<< result_handler => \&result_sub >>

The result_handler argument is optional. The sub is called with it's first and only argument being the return value of work_handler, which is expected to be a hashref. If defined, the boss process calls this sub each time the application requests (and receives) a result. This handler is not timed out via $SIG{ALRM}.

The result_handler is expected to return a hashref.

=item * C<< init_handler => \&init_sub >>

The init_handler argument is optional.  The referenced function receives no arguments and returns nothing.  It is called only once by each worker, just after it's forked off from the boss, and before entering the job processing loop. This subroutine is not affected by the value of global_timeout.  This could be used to connect to a database, instantiate a non-shared object, etc.

=item * C<< exit_handler => \&exit_sub >>

The exit_handler argument is optional.  The referenced function receives no arguments and returns nothing.  It is called only once by each worker, just before exiting.  This subroutine is not affected by the value of global_timeout.  This could be used to disconnect from a database, etc.

=item * C<< global_timeout => $seconds >>

By default, a handler can execute forever. If global_timeout is specified, an alarm is setup to terminate the work_handler so processing can continue.

=item * C<< worker_count => $count >>

By default, 3 workers are started to process the data queue. Specifying worker_count can scale the worker count to any number of workers you wish.

=item * C<< msg_delimiter => $delimiter >>

Sending messages to and from the child processes is accomplished using Data::Dumper. When transmitting data, a delimiter must be used to identify the breaks in messages. By default, this delimiter is "\0\0\0".  This delimiter may not appear in your data.

=item * C<< read_size => $number_of_bytes >>

The default read buffer size is 1 megabyte. The application, the boss, and each worker all sysread() from their respective socket connections. Ideally, the read buffer is just large enough to hold all the data that's ready to read. Depending on your application, the default might be ridiculously large, if for example you only pass lookup keys in, and error codes out. If you're running in a memory-constrained environment, you might lower the buffer significantly, perhaps to 64k (1024 * 64), or all the way down to 1k (1024 bytes). If for example you're passing (copying) high resolution audio/video, you will likely benefit from increasing the buffer size. 

An issue has cropped up, reported in more detail under the Bugs section below. Regardless of how large you set the read buffer with this parameter, BSD ignores this, and uses 8192 bytes instead. This can be a big problem if you pass megs of data back and forth, resulting in so many small reads tha the application appears to hang. It will eventually complete, but it's not pretty. Bottom line: don't pass huge chunks of data cross-process under BSD.

=back

=head2 add_work(\%work)

Adds work to the instance's queue.  It accepts a list of hash refs.  add_work() can be called at any time before shut_down().  All work can be added at the beginning, and then the results gathered, or these can be interleaved: add a few jobs, grab the results of one of them, add a few more, grab more results, etc.

Note: Jobs are not guaranteed to be processed in the order they're added.  This is because they are farmed out to multiple workers running concurrently.

  $bw->add_work({data => "my data"}, {data => "more stuff"}, ...);

=head2 B<pending()>

This simple function returns a true value if there are jobs that have been submitted for which the results have not yet been retrieved.

Note: This says nothing about the readiness of the results.  Just that at some point, now or in the future, the results will be available for collection.

  while ($bw->pending()) { }

=head2 B<get_result()>

Requests the next single available job result from the Boss' result queue.  Returns the return value of the work_handler.  If there is a result_handler defined, it's called here, and the return value of this function is returned instead.  Return from either function is expected to be a hashref. Depending on what your work_handler, or result_handler, does, it may not be interesting to capture this result.

By default, get_result() is a blocking call.  If there are no completed job results available, main application processing will stop here and wait.

  my $href = $bw->get_result();

If you want nonblocking behavior:

  my $href = $bw->get_result( blocking => 0 );
  -OR-
  my $href = $bw->get_result_nb();

In this case, if the call would block, because there is no result to retrieve, it returns immediately, returning undef.

=head2 B<shut_down()>

Tells the Boss and all Workers to exit.  All results should have been retrieved via get_result() prior to calling shut_down().  If shut_down() is called earlier, the queue *will* be processed, but depending on timing the subsequent calls to get_result() may fail if the boss has already written all result data into the socket buffer and exited.

  $bw->shut_down();

If you just want the Boss and Workers to go away, and don't care about work in progress, use:

  $bw->shut_down( force => 1 );

=head1 Error handling

Errors generated by your work_handler do not cause the worker process to die. These are stuffed in the result hash with a key of 'ERROR'. The value is $@.

If global_timeout is set, and a timeout occurs, the worker returns:
  { ERROR => 'BossWorkerAsync: timed out' }

=head1 BUGS

Please report bugs to jvann.cpan@gmail.com.

The Boss and Worker processes are long-lived. There is no restart mechanism for processes that exit prematurely. If it's the Boss, you're dead anyway, but if it's one or more Workers, the app will continue running, but throughput will suck. 

The code should in some way overcome the tiny socket buffer limitations of BSD operating systems. Unbuffered reads are limited to 8192 byte chunks. If you pass megabytes of data with each job, the processing will not fail, but it will seem to be hung -- it can get VERY slow! This is not an issue on Linux, and will not be a problem on BSD if you pass less then say, 64k, between processes. If you know how to force an unbuffered socket read to use an arbitrarily large buffer (1 megabyte, for example), please shoot me an email.

=head1 CREDITS

I'd like to thank everyone who has reported a bug, asked a question, or offered a suggestion.

Jeff Rodriguez: wrote the module Parallel::Fork::BossWorker, which inspired this module.

Rob Navarro: reported -- and fixed! -- errors in fork() error handling, and in the reaping of dead child processes.

Mario Roy: contributed the Windows socket code.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2013 by joe vannucci, E<lt>jvann.cpan@gmail.comE<gt>

All rights reserved.  This library is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
