# Object to handle pending system actions

package RWDE::Scheduler::Pending_action;

use strict;
use warnings;

use Error qw(:try);

use RWDE::Exceptions;

use RWDE::Time;

use base qw(RWDE::DB::Record);

our ($db, $table, $index, $id, @fieldnames, @modifiable_fieldnames, %fields, %static_fields, %modifiable_fields, @static_fieldnames);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 509 $ =~ /(\d+)/;

BEGIN {
  $table = 'pending_actions';
  $id    = 'action_id';
  $index = 'pending_actions_action_id_seq';

  #all of the static fields present in the login table
  %static_fields = (

    # Field => [Type, Descr]
    action_id      => [ 'int',       'Action ID' ],
    action_created => [ 'timestamp', 'Date the action was created' ],
  );

  #all of the fields allowed to be modified in the login table
  %modifiable_fields = (

    # Field => [Type, Descr]
    action_due              => [ 'timestamp', 'Action due date' ],
    action_started          => [ 'timestamp', 'Action start time' ],
    action_completed        => [ 'timestamp', 'Action completed time' ],
    action_type             => [ 'char',      'Class namespace' ],
    action_function         => [ 'char',      'Action function' ],
    action_scheduler_name   => [ 'char',      'Preferred Scheduler' ],
    action_exit_status      => [ 'char',      'Exit Info' ],
    action_params           => [ 'hash',      'Action parameters' ],
    action_repeat_frequency => [ 'char',      'Repeat frequency' ],
    action_priority         => [ 'int',       'Action priority' ],
    action_parent_id        => [ 'int',       'Group actions for identification purpose' ],
    scheduler_id            => [ 'int',       'Taken by scheduler' ],
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

sub create {
  my ($self, $params) = @_;

  my @required = qw( action_type action_function action_params);
  $self->check_params({ required => \@required, supplied => $params });

  my $action = $self->new();

  $action->action_type($$params{action_type});
  $action->action_function($$params{action_function});
  $action->action_params($$params{action_params});
  $action->action_scheduler_name($$params{action_scheduler_name});
  $action->action_due($$params{action_due});

  $action->action_priority($$params{action_priority})  if defined $$params{action_priority};
  $action->action_parent_id($$params{action_parent_id}) if defined $$params{action_parent_id};

  $action->create_record();

  return $action;
}

sub process {
  my ($self, $params) = @_;

  $self->action_started(RWDE::Time->now());
  $self->update_record;

  my $type     = $self->action_type;
  my $function = $self->action_function;

  #build the expression we are going to make
  try {
    my $string = $self->dehashify({ hash => $self->action_params });
    $self->debug_info('devel', "Pending_action::process $type -> $function ($string) ");

    #make the call
    $type->$function($self->action_params);

    $self->action_completed(RWDE::Time->now());
    $self->scheduler_id(0);    #indicates completed action
    $self->action_exit_status('Successful');
    $self->update_record;

    if ($self->is_recurring()) {
      $self->reschedule();
    }

  }

  catch Error with {
    my $ex = shift;

   $self->syslog_msg('warn', $ex);

    RWDE::PostMaster->send_report_message(
      {
        info     => $ex,
        formdata => $self->action_params,
        uri      => 'Pending action doing: ' . $type . '->' . $function,
      }
    );

    #enable re-scheduling for the tasks that explicitly require it
    if ($ex->is_retry() and !$self->is_recurring()) {
      $self->reschedule();
    }

    $self->action_exit_status($ex);
    $self->update_record;
  };

  return ();
}

sub cleanup {
  my ($self, $params) = @_;

  if (defined $self->action_completed) {

    # The action was completed, but the record wasn't released
    # Mark as completed
    $self->scheduler_id(0);
  }

  else {

    # The action has not completed
    # return the action to the pool to be picked up by a new scheduler
    $self->scheduler_id('NULL');
  }

  $self->update_record;

  return ();
}

sub is_recurring {
  my ($self, $params) = @_;

  return (defined $self->action_repeat_frequency);
}

sub reschedule {
  my ($self, $params) = @_;

  my $interval;

  if (defined $self->action_repeat_frequency) {
    $interval = $self->action_repeat_frequency;
  }

  elsif (defined $$params{interval}) {
    $interval = $$params{interval};
  }

  else {
    $interval = '15 minutes';
  }

  my $new_action = $self->new;

  $new_action->action_type($self->action_type);
  $new_action->action_function($self->action_function);
  $new_action->action_params($self->action_params);
  $new_action->action_scheduler_name($self->action_scheduler_name);
  $new_action->action_repeat_frequency($self->action_repeat_frequency);

  my $new_runtime = RWDE::Time->fetch_time({ timestamp => 'NOW()', interval => $interval });
  $new_action->action_due($new_runtime);

  $new_action->create_record();

  return $new_action;
}

sub count_outstanding {
  my ($self, $params) = @_;

  return $self->count_query({ query => "action_due < NOW() AND scheduler_id IS NULL AND action_repeat_frequency IS NULL", });
}

1;
