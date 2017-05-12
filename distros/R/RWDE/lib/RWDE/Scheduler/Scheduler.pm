# Object to handle subscriber records (Scheduler.pm)

# Multiple processes may be run locally or on multiple hosts.

# Upon startup, does sanity checks on the tables to ensure everything
# is as expected.

# On SIGTERM signal, kills off all of its own children.  Upon restart,
# these will be resumed.  SIGUSR1 turns on debug messages to syslog.

package RWDE::Scheduler::Scheduler;

use strict;
use warnings;

use Error qw(:try);

use POSIX qw(:sys_wait_h setsid ceil);

use RWDE::DB::DbRegistry;
use RWDE::DB::Record;
use RWDE::Exceptions;
use RWDE::Time;

use RWDE::Scheduler::SchedulerWorker;
use RWDE::Scheduler::Pending_action;

use base qw(RWDE::DB::DefaultDB RWDE::DB::Deletable RWDE::DB::Record RWDE::Runnable);

our ($db, $table, $index, $id, @fieldnames, $ccrcontext, %fields, %static_fields, %modifiable_fields, @static_fieldnames, @modifiable_fieldnames);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 535 $ =~ /(\d+)/;

BEGIN {
  $table = 'schedulers';
  $id    = 'scheduler_id';
  $index = 'schedulers_scheduler_id_seq';

  #all of the static fields present in the scheduler table
  %static_fields = (

    # Field => [Type, Descr]
    scheduler_id      => [ 'int',       'Scheduler ID' ],
    scheduler_created => [ 'timestamp', 'Scheduler created on' ],    # datetime
    lastmod           => [ 'timestamp', 'last seen' ],
  );

  #all of the fields allowed to be modified in the scheduler table
  %modifiable_fields = (

    # Field => [Type, Descr]
    scheduler_terminated => [ 'timestamp', 'Scheduler created on' ],    # datetime
    scheduler_name       => [ 'char',      'Scheduler name' ],
    scheduler_pid        => [ 'char',      'Scheduler process id' ],
    scheduler_status     => [ 'char',      'Scheduler status' ],
  );

  %fields = (%static_fields, %modifiable_fields);

  @static_fieldnames     = sort keys %static_fields;
  @modifiable_fieldnames = sort keys %modifiable_fields;
  @fieldnames            = sort keys %fields;

}

sub fetch_by_name {
  my ($self, $params) = @_;

  my $scheduler;
  if (exists($$params{scheduler_name})) {
    $scheduler = $self->fetch_one(
      {
        query        => 'scheduler_name = ?',
        query_params => [ $$params{scheduler_name} ]
      }
    );
  }
  else {
    throw RWDE::DevelException({ info => 'Scheduler::Inappropriate parameters passed to fetch_by_name' });
  }

  return $scheduler;
}

sub get_workers {
  my ($self, $params) = @_;

  return RWDE::Scheduler::SchedulerWorker->fetch({ query => 'scheduler_id = ?', query_params => [ $self->scheduler_id ] });
}

sub get_pending_actions {
  my ($self, $params) = @_;

  if (!$self->{Pending_actions}) {
    $self->{Pending_actions} = RWDE::Scheduler::Pending_action->fetch({ query => 'scheduler_id = ?', query_params => [ $self->scheduler_id ] });
  }
  return $self->{Pending_actions};
}

# Get a job for a worker, if available, and this scheduler is the one with most free schedulers, take the job
# Mark the job as taken inside of the database so nobody else takes it
# This has the side-effect of temporarily locking the db, but hopefully for a very short time
sub get_next_job {
  my ($self, $params) = @_;

  $self->debug_info('devel', 'Scheduler::get_next_job');
  my $action;

  try {

    #begin a transaction
    transaction {

      #election query
      $action = RWDE::Scheduler::Pending_action->fetch_one(
        {
          query        => "action_due < NOW() AND scheduler_id IS NULL AND (action_scheduler_name IS NULL or action_scheduler_name = ?) ORDER BY action_priority,action_due",
          query_params => [ $self->scheduler_name ],
        }
      );

      $action->scheduler_id($self->scheduler_id);
      $action->update_record();
    };
  }

  catch RWDE::DataNotFoundException with {
    my $ex = shift;

    #there was no work found
  };

  return $action;
}

sub cleanup {
  my ($self, $params) = @_;

  # get all the outstanding workers
  foreach my $worker (@{ $self->get_workers }) {
    $worker->cleanup;
  }

  #get all the reserved jobs (might not be assigned to workers
  foreach my $job (@{ $self->get_pending_actions }) {
    $self->debug_info('devel', 'Cleaning_up for job: ' . $job->action_id);
    $job->cleanup;
  }

  $self->delete_record;

  return ();
}

sub terminate_scheduler {
  my ($self, $params) = @_;

  $self->syslog_msg('info', 'Terminating scheduler');

  $self->scheduler_status('terminated');
  $self->scheduler_terminated(RWDE::Time->now());
  $self->scheduler_pid(0);
  $self->update_record;

  return;
}

sub fork_off {
  my ($self, $params) = @_;

  my $job = $$params{job};

  # fork a child to run the job
  my $cpid = fork;

  if (not defined $cpid or $cpid) {

    #parent
    $self->add_job($cpid, $job);
    return ();
  }

  else {

    #child
    my $result = RWDE::Scheduler::SchedulerWorker->run({ job => $job, scheduler_id => $self->scheduler_id });
    exit($result);
  }

}

# cleanup: After child terminates, perform housekeeping
sub child_cleanup {
  my ($self, $cpid, $status) = @_;

  $self->debug_info('devel', "Cleanup for child $cpid, exited with $status");
  $self->remove_job($cpid);

  return;
}

sub print_status {
  my ($self) = @_;

  $self->debug_info('info', sprintf("%-10s %-10s %10s\n", 'PID', 'MSGID', 'RUNNING'));

  my $active_jobs_ref = $self->{active_jobs};

  foreach my $cpid (keys %{$active_jobs_ref}) {
    my $alive = kill 0, $cpid;
    my $job = $active_jobs_ref->{$cpid};
    $self->debug_info('info', sprintf("%-10d %-10d %10s\n", $cpid, $job->action_id, $alive ? 'yes' : 'no'));
  }

  return;
}

sub add_job {
  my ($self, $cpid, $job) = @_;

  my $active_jobs_ref = $self->{active_jobs};
  $active_jobs_ref->{$cpid} = $job;

  $self->{workers_free} = $self->{workers_free} - 1;

  return;
}

sub remove_job {
  my ($self, $cpid) = @_;

  my $active_jobs_ref = $self->{active_jobs};

  if (exists $active_jobs_ref->{$cpid}) {

    #remove the job from the active jobs
    delete $active_jobs_ref->{$cpid};

    #we are going back into the worker pool now
    $self->{workers_free} = $self->{workers_free} + 1;
  }
  else {
    $self->syslog_msg('warning', 'waitpid got unknown pid: ' . $cpid);
  }

  return;
}

sub get_active_jobs {
  my ($self) = @_;

  my $active_jobs = $self->{active_jobs};

  return keys(%{$active_jobs});
}

sub setup {
  my ($self, $params) = @_;

  # Process command line options:
  #  -s SECONDS   seconds to sleep between scans. Default 180.
  #  -m PROCS     Max number of workers. Default 5.
  #  -n NAME      The name for the scheduler
  #################################################################################################

  my $sleeptime = $$params{s} || 30;
  my $workers   = $$params{m} || 5;
  my $name      = $$params{n} || "temp";

  # Before we start, make sure we tidy up the remnants of my previous run(s)
  try {
    my $previous_run = $self->fetch_by_name({ scheduler_name => $name });
    $previous_run->cleanup();
  }

  catch RWDE::DataNotFoundException with {
    my $ex = shift;

    # there are no schedulers with the same name
  };

  # non-persistent fields
  $self->{workers_free} = $self->{workers}     = $workers;
  $self->{sleeptime}    = $sleeptime;
  $self->{cleanup}      = $self->{terminating} = $self->{printstatus} = 0;    # initialize for sig handler safety.
  $self->{active_jobs} = {};

  # setup signal handlers
  $SIG{'TERM'} = $SIG{'INT'} = sub { $self->{terminating} = 1; };
  $SIG{'INFO'} = sub { $self->{printstatus} = 1; };
  $SIG{'CHLD'} = sub { $self->{cleanup}     = 1; };

  # persistent fields
  $self->scheduler_name($name);
  $self->scheduler_status('running');
  $self->scheduler_pid($$);

  # Register ourselves, so other schedulers know we are running
  $self->create_record;

  return ();
}

sub start {
  my ($self, $params) = @_;
  
  # set a listener for  DB notifications
  RWDE::DB::DbRegistry->add_db_settings({ db => $self->get_db, db_settings => ['LISTEN pending'], });

  $self->syslog_msg('info', "Starting Scheduler:: name: " . $self->scheduler_name . " sleeptime: " . $self->{sleeptime} . " workers: " . $self->{workers});

  while (1) {

    # check for any child processes that have terminated
    if ($self->{cleanup}) {    # set by SIGCHLD handler
      $self->debug_info('devel', 'reaping old children');
      while ((my $cpid = waitpid(-1, WNOHANG)) > 0) {
        $self->child_cleanup($cpid, $?);
      }
      $self->{cleanup} = 0;
    }

    if ($self->{printstatus}) {    # set by SIGUSR1 handler
      $self->print_status();
      $self->{printstatus} = 0;
    }

    if ($self->{terminating} and ($self->get_active_jobs == 0)) {
      $self->terminate_scheduler();
      exit(0);
    }

    if ($self->{workers_free} > 0 && !($self->{terminating})) {
      $self->debug_info('devel', 'Number of workers: ' . $self->{workers_free});
      my $action = $self->get_next_job();
      if (defined $action) {
        $self->fork_off({ job => $action });
      }
    }

    else {
      $self->debug_info('devel', 'No free workers');
    }

  }
  continue {
    my $notifications_ref = RWDE::DB::DbRegistry->get_db_notifications({ sleeptime => $self->{sleeptime}, db => $self->get_db() });
  }

  return;
}

1;

