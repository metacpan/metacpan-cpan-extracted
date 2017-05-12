package RWDE::Scheduler::SchedulerWorker;

use strict;
use warnings;

use Error qw(:try);

use RWDE::Exceptions;

use base qw(RWDE::DB::Deletable RWDE::DB::Record);

our ($db, $table, $index, $id, @fieldnames, $ccrcontext, %fields, %static_fields, %modifiable_fields, @static_fieldnames, @modifiable_fieldnames);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 534 $ =~ /(\d+)/;

BEGIN {
  $table = 'workers';
  $id    = 'worker_id';
  $index = 'workers_worker_id_seq';

  #all of the static fields present in the worker table
  %static_fields = (

    # Field => [Type, Descr]
    worker_id => [ 'int', 'Worker ID' ],
  );

  #all of the fields allowed to be modified in the worker table
  %modifiable_fields = (

    # Field => [Type, Descr]
    action_id    => [ 'int', 'Scheduler ID' ],
    scheduler_id => [ 'int', 'Scheduler ID' ],
    worker_pid   => [ 'int', 'Worker process id' ],

  );

  %fields = (%static_fields, %modifiable_fields);

  @static_fieldnames     = sort keys %static_fields;
  @modifiable_fieldnames = sort keys %modifiable_fields;
  @fieldnames            = sort keys %fields;

}

## @method object get_db()
# (Enter get_db info here)
# @return
sub get_db {
  my ($self, $params) = @_;

  return 'default';
}

sub cleanup {
  my ($self, $params) = @_;

  $self->delete_record;

  return;
}

sub run {
  my ($self, $params) = @_;

  my @required = qw( job scheduler_id );
  $self->check_params({ required => \@required, supplied => $params });

  # to avoid contention: release the reference to parent's db handle
  # the handles are shared between parents and children
  RWDE::DB::DbRegistry->destroy_dbh({ db => $self->get_db() });

  my $worker = $self->new();
  my $job    = $$params{job};

  $worker->scheduler_id($$params{scheduler_id});
  $worker->action_id($job->action_id);
  $worker->worker_pid($$);
  $worker->create_record;

  try {
    $job->process;
  }
  catch Error with {
    my $ex = shift;                                                    
   $self->syslog_msg('info', "Worker::run caught an unhandled exception $ex ");
  };

  $worker->delete_record;

  return (0);
}

1;
