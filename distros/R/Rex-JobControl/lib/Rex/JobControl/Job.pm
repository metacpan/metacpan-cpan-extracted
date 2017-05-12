#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::JobControl::Job;
$Rex::JobControl::Job::VERSION = '0.18.0';
use Mojo::Base 'Mojolicious::Controller';
use DateTime;

sub prepare_stash {
  my $self = shift;

  my $project = $self->project( $self->param("project_dir") );
  $self->stash( project => $project );

  my $job = $project->get_job( $self->param("job_dir") );
  $self->stash( job => $job );

  $self->stash( is_logged_in => $self->is_user_authenticated );
}

sub edit_save {
  my $self = shift;

  my $pr  = $self->project( $self->param("project_dir") );
  my $job = $pr->get_job( $self->param("job_dir") );

  $job->update(
    name             => $self->param("job_name"),
    description      => $self->param("job_description"),
    environment      => $self->param("environment"),
    fail_strategy    => $self->param("fail_strategy"),
    execute_strategy => $self->param("execute_strategy"),
    steps            => [ split( /,/, $self->param("hdn_workflow_steps") ) ],
  );

  $self->redirect_to(
    "/project/" . $pr->directory . "/job/" . $job->directory );
}

sub job_delete {
  my $self = shift;

  my $pr  = $self->project( $self->param("project_dir") );
  my $job = $pr->get_job( $self->param("job_dir") );

  $job->remove;

  $self->flash(
    {
      title   => "Job removed",
      message => "Job <b>" . $job->name . "</b> removed.",
    }
  );

  $self->redirect_to( "/project/" . $pr->directory );
}

sub view {
  my $self = shift;

  my $project = $self->project( $self->param("project_dir") );
  my $job     = $project->get_job( $self->param("job_dir") );

  my $last_time = $job->last_execution;

  $self->app->log->debug("got last execution: $last_time");

  if ( $last_time == 0 ) {
    $self->stash( last_execution => '-' );
  }
  else {
    my $dt = DateTime->from_epoch( epoch => $last_time );
    $self->stash( last_execution => $dt->ymd("-") . " " . $dt->hms(":") );
  }
  $self->stash( last_status => $job->last_status );

  $self->render;
}

sub job_new {
  my $self = shift;
  $self->render;
}

sub job_new_create {
  my $self = shift;

  $self->app->log->debug( "Got project name: " . $self->param("project_dir") );
  $self->app->log->debug( "Got job name: " . $self->param("job_name") );

  my $pr = $self->project( $self->param("project_dir") );
  $pr->create_job(
    directory        => $self->param("job_name"),
    name             => $self->param("job_name"),
    description      => $self->param("job_description"),
    environment      => $self->param("environment"),
    fail_strategy    => $self->param("fail_strategy"),
    execute_strategy => $self->param("execute_strategy"),
    steps            => [ split( /,/, $self->param("hdn_workflow_steps") ) ],
  );

  $self->flash(
    {
      title   => "Job created",
      message => "A new job <b>"
        . $self->param("job_name")
        . "</b> was created.",
    }
  );

  $self->redirect_to( "/project/" . $self->param("project_dir") );
}

sub job_execute {
  my $self = shift;

  my $pr         = $self->project( $self->param("project_dir") );
  my $all_server = $pr->all_server;

  $self->stash( all_server => $all_server );

  $self->render('job/execute');
}

sub job_execute_dispatch {
  my $self = shift;

  my $pr  = $self->project( $self->param("project_dir") );
  my $job = $pr->get_job( $self->param("job_dir") );

  $self->minion->enqueue(
    execute_rexfile => [
      $pr->directory,              $job->directory,
      $self->current_user->{name}, undef,
      $self->param("sel_server"),
    ]
  );

  $self->flash(
    {
      title   => "Execution started",
      message => "The execution of <b>"
        . $job->name
        . "</b> on <b>"
        . join( ", ", $self->param("sel_server") )
        . "</b> started in background.",
    }
  );

  $self->redirect_to(
    "/project/" . $pr->directory . "/job/" . $job->directory );
}

sub view_output_log {
  my $self = shift;
  $self->render;
}

1;
