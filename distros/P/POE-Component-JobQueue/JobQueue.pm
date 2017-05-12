# $Id: JobQueue.pm 29 2009-07-28 06:33:37Z rcaputo $
# License and documentation are after __END__.

package POE::Component::JobQueue;

use strict;

use vars qw($VERSION);
$VERSION = '0.571';

use Carp qw (croak);

use POE::Session;

sub DEBUG () { 0 };

# Spawn a new PoCo::JobQueue session.  This basically is a
# constructor, but it isn't named "new" because it doesn't create a
# usable object.  Instead, it spawns the object off as a session.

sub spawn {
  my $type = shift;

  croak "$type requires an even number of parameters" if @_ % 2;

  my %params = @_;

  ### Parameters that are common to both types of job queue.

  my $alias = delete $params{Alias};
  $alias = 'queuer' unless defined $alias and length $alias;

  my $worker = delete $params{Worker};
  croak "$type requires a coderef Worker parameter"
    unless defined $worker and ref($worker) eq 'CODE';

  my $worker_limit = delete $params{WorkerLimit};
  $worker_limit = 8 unless defined $worker_limit and $worker_limit > 0;

  croak "$type requires either an Active or a Passive parameter block"
    unless defined($params{Active}) xor defined($params{Passive});

  ### Parameters and states that are common to both types of queue.

  my @args    = ( $alias, $worker_limit, $worker );
  my %states  =
    ( _child  => \&poco_jobqueue_both_child,
      stop    => \&poco_jobqueue_both_stop,
      _stop   => sub {},
    );

  ### Modal parameters and states go here.

  # Set up for an active queue.
  if (exists $params{Active}) {
    my $active = delete $params{Active};

    my $poll_interval = delete $active->{PollInterval};
    $poll_interval = undef
      unless defined $poll_interval and $poll_interval > 0;

    my $ack_alias = delete $active->{AckAlias};
    $ack_alias = undef unless defined $ack_alias and length $ack_alias;

    my $ack_state = delete $active->{AckState};
    $ack_state = undef unless defined $ack_state and length $ack_state;

    croak "$type must have neither or both AckAlias and AckState"
      if defined($ack_alias) xor defined($ack_state);

    $states{_start}  = \&poco_jobqueue_active_start;
    $states{dequeue} = \&poco_jobqueue_active_dequeue;

    push @args, $poll_interval, $ack_alias, $ack_state;
  }

  # Set up for a passive queue.
  elsif (exists $params{Passive}) {
    my $passive = delete $params{Passive};

    my $prioritizer = delete $passive->{Prioritizer};
    $prioritizer = sub { 1 } unless defined $prioritizer;

    croak( "$type doesn't know these Passive parameters: ",
           join(', ', sort keys %$passive)
         ) if scalar keys %$passive;

    $states{_start}  = \&poco_jobqueue_passive_start;
    $states{dequeue} = \&poco_jobqueue_passive_dequeue;
    $states{enqueue} = \&poco_jobqueue_passive_enqueue;

    push @args, $prioritizer;
  }

  croak( "$type doesn't know these parameters: ",
         join(', ', sort keys %params)
       ) if scalar keys %params;

  # Spawn whichever queue we've built.
  POE::Session->create
    ( inline_states => \%states,
      args          => \@args,
    );

  undef;
}

# Helper function for active job queues.

sub poco_jobqueue_active_meta_postback {
  die "unimplemented bit";
}

# Start an active job queue.  This type of queue polls for new jobs.

sub poco_jobqueue_active_start {
  my ( $kernel, $heap,
       $alias, $worker_limit, $worker_ref,
       $poll_interval, $ack_alias, $ack_state
     ) = @_[KERNEL, HEAP, ARG0..ARG5];

  # Common parameters.
  $heap->{alias}         = $alias;
  $heap->{worker_limit}  = $worker_limit;
  $heap->{worker_ref}    = $worker_ref;

  # Active queue parameters.
  $heap->{poll_interval} = $poll_interval;
  $heap->{meta_postback} =
    sub {
      my @job = @_;
      my $session = $kernel->alias_resolve( $ack_alias );
      return $session->postback( $ack_state, @job ) if defined $session;
      return sub { 1 };
    };

  # State variables.  Pending polls starts at 1 because we're going to
  # fake an initial poll to get things started.
  $heap->{worker_count}  = 0;
  $heap->{pending_polls} = 0;
  $heap->{latest_worker} = 0;

  # Register an alias.
  $kernel->alias_set($alias);

  # Start an initial set of workers.
  $kernel->yield( 'dequeue' );
}

# Start a passive job queue.  This type of queue waits for something
# else to enqueue jobs.

sub poco_jobqueue_passive_start {
  my ( $kernel, $heap,
       $alias, $worker_limit, $worker_ref,
       $prioritizer
     ) = @_[KERNEL, HEAP, ARG0..ARG3];

  # Common parameters.
  $heap->{alias}         = $alias;
  $heap->{worker_limit}  = $worker_limit;
  $heap->{worker_ref}    = $worker_ref;

  # Active queue parameters.
  $heap->{prioritizer}   = $prioritizer;

  # State variables.
  $heap->{worker_count}  = 0;
  $heap->{job_queue}     = [ ];

  # Register an alias.
  $kernel->alias_set($alias);
}

# A worker either has come or gone.  Track the number of running
# workers, and spawn new ones if appropriate.

sub poco_jobqueue_both_child {
  my ($kernel, $heap, $operation) = @_[KERNEL, HEAP, ARG0];

  # A worker has begun its job.  Count it so we know how many exist.

  if ($operation eq 'gain' or $operation eq 'create') {
    DEBUG and warn "JQ: job queue $heap->{alias} got a new worker";
    $heap->{worker_count}++;
  }

  # A worker has finished.  Decrement our worker count, and try to
  # start another worker to take its place.

  else {
    DEBUG and warn "JQ: job queue $heap->{alias} lost a worker";
    warn( "worker count ($heap->{worker_count}) exceeded the limit (",
          $heap->{worker_limit}, ")"
        ) if $heap->{worker_count} > $heap->{worker_limit};
    $heap->{worker_count}--;
    $kernel->yield('dequeue') unless (
      $heap->{latest_worker} or $heap->{stopped}
    );
  }
}

# Remove the alias, stop active polling and delete outstanding job queue

sub poco_jobqueue_both_stop {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  $kernel->alias_remove($heap->{alias});
  $kernel->alarm_remove_all();

  delete $heap->{pollinterval} if ($heap->{pollinterval});
  delete $heap->{job_queue} if ($heap->{job_queue});

  $heap->{stopped} = 1;
}

# Attempt to fill empty worker slots.

# This is a token for ARG0 that signifies this was a timed event.
sub TIMED () { 31415 }

sub poco_jobqueue_active_dequeue {
  my ($kernel, $heap, $is_timed) = @_[KERNEL, HEAP, ARG0];

  # If this is a poll from a timed event, then decrement the pending
  # polls count.  The pending polls count is just to ensure that
  # redundant delays are not set, because each redundant delay would
  # force the existing one forward in time.  They would delay polling
  # past the hard polling interval, which would probably be bad (and
  # could stave off polling indefinitely in some instances).  I think
  # this is a bit of a hack, and something better should replace it.

  if (defined $is_timed and $is_timed == TIMED) {
    # Decrement the number of pending polls.  There can be only one,
    # so throw in a die for assertion testing.
    die "pending polls should now be zero (not $heap->{pending_polls})"
      if --$heap->{pending_polls};
  }

  # Attempt to fill the empty worker slots.
  while (
    not $heap->{stopped}
    and $heap->{worker_count} < $heap->{worker_limit}
  ) {

    # Call the worker to fetch a new job and spawn a session.
    my $previous_worker_count = $heap->{worker_count};
    $heap->{worker_ref}->( $heap->{meta_postback} );

    # If the worker count hasn't changed, then we've run out of jobs.
    # Begin polling, if applicable, and exit the spawn loop.
    if ($heap->{worker_count} == $previous_worker_count) {
      if (defined $heap->{poll_interval} and !$heap->{pending_polls}) {
        $heap->{pending_polls}++;
        $kernel->delay( dequeue => $heap->{poll_interval} => TIMED );
      }
      $heap->{latest_worker}++ unless defined $heap->{poll_interval};
      last;
    }
  }
}

# Attempt to fill empty worker slots.

sub poco_jobqueue_passive_dequeue {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  # Attempt to fill the empty worker slots.
  while (
    not $heap->{stopped}
    and $heap->{worker_count} < $heap->{worker_limit}
  ) {

    # Try to fetch another job from the queue.
    my $next_job = shift @{ $heap->{job_queue} };
    last unless defined $next_job;

    DEBUG and
      warn "JQ: job queue $heap->{alias} is starting a new worker";

    # Start a new session with the job.
    $heap->{worker_ref}->( @$next_job );
  }

  # Avoid accidentally returning something.
  undef;
}

# Enqueue a job in a passive queue.

sub poco_jobqueue_passive_enqueue {
  my ($kernel, $sender, $heap, $return_state, @job) =
    @_[KERNEL, SENDER, HEAP, ARG0..$#_];

  if ($heap->{stopped}) {
    DEBUG and warn(
      "JQ: $heap->{alias} can not enqueue new jobs after 'stop'\n"
    );

    return;
  }

  DEBUG and warn "JQ: job queue $heap->{alias} enqueuing a new job";

  my $postback;
  if (defined $return_state) {
    $postback = $sender->postback( $return_state, @job );
  }

  # Add the job to the queue.  Use the prioritizer to find the right
  # place to put it.

  my $queue_index = @{ $heap->{job_queue} };
  while ($queue_index--) {
    last if
      $heap->{prioritizer}->( $heap->{job_queue}->[$queue_index],
                              \@job,
                            ) >= 0;
  }

  # Place the new job after the index we found.
  splice( @{$heap->{job_queue}}, $queue_index+1, 0, [ $postback, @job ] );

  # Dequeue a new event.
  $kernel->yield( 'dequeue' );
}

1;

__END__

=head1 NAME

POE::Component::JobQueue - a component to manage queues and worker pools

=head1 SYNOPSIS

  use POE qw(Component::JobQueue);

  # Passive queue waits for enqueue events.
  POE::Component::JobQueue->spawn
    ( Alias         => 'passive',         # defaults to 'queuer'
      WorkerLimit   => 16,                # defaults to 8
      Worker        => \&spawn_a_worker,  # code which will start a session
      Passive       =>
      { Prioritizer => \&job_comparer,    # defaults to sub { 1 } # FIFO
      },
    );

  # Active queue fetches jobs and spawns workers.
  POE::Component::JobQueue->spawn
    ( Alias          => 'active',          # defaults to 'queuer'
      WorkerLimit    => 32,                # defaults to 8
      Worker         => \&fetch_and_spawn, # fetch a job and start a session
      Active         =>
      { PollInterval => 1,                 # defaults to undef (no polling)
        AckAlias     => 'respondee',       # defaults to undef (no respondee)
        AckState     => 'response',        # defaults to undef
      },
    );

  # Enqueuing a job in a passive queue.
  $kernel->post( 'passive',   # post to 'passive' alias
                 'enqueue',   # 'enqueue' a job
                 'postback',  # which of our states is notified when it's done
                 @job_params, # job parameters
               );

  # Passive worker function.
  sub spawn_a_worker {
    my ($postback, @job_params) = @_;     # same parameters as posted
    POE::Session->create
      ( inline_states => \%inline_states, # handwaving over details here
        args          => [ $postback,     # $postback->(@results) to return
                           @job_params,   # parameters of this job
                         ],
      );
  }

  # Active worker function.
  sub fetch_and_spawn {
    my $meta_postback = shift;               # called to create a postback
    my @job_params = &fetch_next_job();      # fetch the next job's parameters
    if (@job_params) {                       # if there's a job to do...
      my $postback = $meta_postback->(@job_params); # ... create a postback
      POE::Session->create                          # ... create a session
        ( inline_states => \%inline_states,  # handwaving over details here
          args          => [ $postback,      # $postback->(@results) to return
                             @job_params,    # parameters of this job
                           ],
        );
    }
  }

  # Invoke a postback to acknowledge that a job is done.
  $postback->( @job_results );

  # This is the sub which is called when a postback is invoked.
  sub postback_handler {
    my ($request_packet, $response_packet) = @_[ARG0, ARG1];

    my @original_job_params = @{$request_packet};  # original post/fetch
    my @job_results         = @{$response_packet}; # passed to the postback

    print "original job parameters: (@original_job_params)\n";
    print "results of finished job: (@job_results)\n";
  }

  # Stop a running queue
  $kernel->call( 'active' => 'stop' );

=head1 DESCRIPTION

POE::Component::JobQueue manages a finite pool of worker sessions as
they handle an arbitrarily large number of tasks.  It often is used as
a form of flow control, preventing a large group of tasks from
exhausting some sort of resource.

PoCo::JobQueue implements two kinds of queue: active and passive.
Both kinds of queue use a Worker coderef to spawn sessions that
process jobs, but how they use the Worker differs between them.

Active queues' Worker code fetches a new job from a resource that must
be polled.  For example, it may read a new line from a file.  Passive
queues, on the other hand, are given jobs with 'enqueue' events.
Their Worker functions are passed the next job as parameters.

JobQueue components are not proper objects.  Instead of being created,
as most objects are, they are "spawned" as separate sessions.  To
avoid confusion (and hopefully not cause other confusion), they must
be spawned wich a C<spawn> method, not created anew with a C<new> one.

POE::Component::JobQueue's C<spawn> method takes different parameters
depending whether it's going to be an active or a passive session.
Regardless, there are a few parameters which are the same for both:

=over 2

=item Alias => $session_alias

C<Alias> sets the name by which the session will be known.  If no
alias is given, the component defaults to "queuer".  The alias lets
several sessions interact with job queues without keeping (or even
knowing) hard references to them.  It's possible to spawn several
queues with different aliases.

=item WorkerLimit => $worker_count

C<WorkerLimit> sets the limit on the number of worker sessions which
will run in parallel.  It defaults arbitrarily to 8.  No more than
this number of workers will be active at once.

=item Worker => \&worker

C<Worker> is a coderef which is called whenever it's time to spawn a
new session.  What it receives as parameters and what it's expected to
do are slightly different for active and passive sessions.

Active workers receive just one parameter: a meta-postback.  This is
used to build a postback once the next job's parameters are known.
They're expected to actively fetch the next job's parameters and spawn
a new session if necessary.

See C<sub fetch_and_spawn> in the SYNOPSIS for an example of an active
worker function.>

Passive workers' arguments include a pre-built postback and the next
job's parameters.  Since the JobQueue component already knows what the
job parameters are, it's done most of the work for the worker.  All
that's left is to spawn the session that will process the job.

See C<sub spawn_a_worker> in the SYNOPSIS for an example of a passive
worker function.

When a postback is called, it posts its parameters (plus the
parameters passed when it was created) to the session it belongs to.
Postbacks are discussed in the POE::Session manpage.

=back

These parameters are unique to passive queues:

=over 2

=item Passive => \%passive_parameters

C<Passive> contains a hashref of passive queue parameters.  The
C<Passive> parameter block's presence indicates that the queue will be
passive, but its contents may be empty since all its parameters are
optional:

  Passive => { }, # all passive parameters take default values

A queue can't be both active and passive at the same time.

The C<Passive> block takes up to one parameter.

=over 2

=item Prioritizer => \&prioritizer_function

C<Prioritizer> holds a function that defines how a job queue will be
ordered.  The prioritizer function receives references to two jobs,
and it returns a value which tells the JobQueue component which job
should be dealt with first.

In the Unix tradition, lower priorities go first.  This transforms the
prioritizer into a simple sort function, which it has been modelled
after.  Like sort's sorter sub, the prioritizer returns -1 if the
first job goes before the second one; 0 if both jobs have the same
priority; and 1 if the first job goes after the second.  It's easier
to write an example than to describe it:

  sub low_priorities_first {
    my ($first_job, $second_job) = @_;
    return $first_job->{priority} <=> $second_job->{priority};
  }

The first argument always refers to the new job being enqueued.

The default prioritizer always returns 1.  Since the first argument
always refers to the new job being enqueued, this effects a FIFO
queue.  Replacing it with a prioritizer that always returns -1 will
turn the JobQueue into a stack (last in, first out).

=back

These parameters are unique to active queues:

=over 2

=item Active => \%active_parameters

C<Active> contains a hashref of active queue parameters.  The
C<Active> parameter block's presence indicates that the queue will be
active, but its contens may be empty since all its parameters are
optional.

  Active => { }, # all active parameters take default values

A queue can't be both active and passive at the same time.

The C<Active> block takes up to three parameters.

=over 2

=item PollInterval => $seconds

Active C<Worker> functions indicate that they've run out of jobs by
failing to spawn new sessions.  When this happens, an active queue may
go into "polling" mode.  In this mode, the C<Worker> is called
periodically to see if new jobs have appeared in whatever it's getting
them from.

C<PollInterval>, if present, tells the job queue how often to call
C<Worker> in the absence of new sessions.  If it's omitted, the active
queue stops after the first time it runs out of jobs.

=item AckAlias => $alias

=item AckState => $state

C<AckAlias> and C<AckState> tell the active job queue where to send
acknowledgements of jobs which have been completed.  If one is
specified, then both must be.

=back

=back

Sessions communicate asynchronously with passive JobQueue components.
They post "enqueue" requests to it, and it posts job results back.

Requests are posted to the component's "enqueue" state.  They include
the name of a state to post responses back to, and a list of job
parameters.  For example:

  $kernel->post( 'queue', 'enqueue', # queuer session alias & state
                 'job_results',      # my state to receive responses
                 @job_parameters,    # parameters of the job
               );

Once the job is completed, the handler for 'job_results' will be
called with the job parameters and results.  See C<sub
postback_handler> in the SYNOPSIS for an example results handler.

Active JobQueue components act as event generators.  They don't
receive jobs from the outside; instead, they poll for them and post
acknowledgements as they're completed.

Running queues can be stopped by posting a "stop" state to the 
component. Any currently running workers will be allowed to 
complete, but no new workers will be started.

  $kernel->call( 'queue' => 'stop' ); # Stop the running queue

=head1 SEE ALSO

This component is built upon and POE.  Please see its source code and
the documentation for its foundation modules to learn more.

Also see the test program, t/01_queues.t, in the
POE::Component::JobQueue distribution.

=head1 BUG TRACKER

https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=POE-Component-JobQueue

=head1 REPOSITORY

http://thirdlobe.com/svn/poco-jobqueue/

=head1 OTHER RESOURCES

http://search.cpan.org/dist/POE-Component-JobQueue/

=head1 AUTHOR & COPYRIGHTS

POE::Component::JobQueue is Copyright 1999-2009 by Rocco Caputo.  All
rights are reserved.  POE::Component::JobQueue is free software; you
may redistribute it and/or modify it under the same terms as Perl
itself.

=cut
