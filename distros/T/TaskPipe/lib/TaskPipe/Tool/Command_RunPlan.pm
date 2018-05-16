package TaskPipe::Tool::Command_RunPlan;

use Moose;
use TaskPipe::SchemaManager;
use TaskPipe::LoggerManager;
use TaskPipe::Task_Scrape::Settings;
use TaskPipe::Plan;
use Module::Runtime;
use TaskPipe::JobManager;
use DateTime;
extends 'TaskPipe::Tool::Command';
with 'MooseX::ConfigCascade';


has option_specs => (is => 'ro', isa => 'ArrayRef', default => sub{[{
    module => 'TaskPipe::PathSettings::Global',
    items => [
        'project_root',
        'project',
    ],
    is_config => 1
}, {
    module => 'TaskPipe::PathSettings::Project',
    items => [
        'plan',
        'lib_dir',
        'plan_dir',
        'source_dir',
        'log_dir'
    ],
    is_config => 1
}, {
    module => 'TaskPipe::Plan::Settings',
    is_config => 1
}]});


has schema_manager => (is => 'rw', isa => 'TaskPipe::SchemaManager', lazy => 1, default => sub{
    my $sm = TaskPipe::SchemaManager->new;
    $sm->connect_schema;
    return $sm;
});



has job_manager => (is => 'ro', isa => 'TaskPipe::JobManager', lazy => 1, default  => sub{
    TaskPipe::JobManager->new(
        name => $_[0]->name,
        project => $_[0]->schema_manager->path_settings->project_name,
        shell => $_[0]->plan->settings->shell
    );
});


has plan => (is => 'rw', isa => 'TaskPipe::Plan', lazy => 1, default => sub{
    TaskPipe::Plan->new(
        schema_manager => $_[0]->schema_manager
    );
});




sub execute{

    my ($self) = @_;

#    $self->plan->task->rinfo->job_id( $self->job_manager->job_id );
#    $self->plan->task->rinfo->orig_cmd( $self->orig_cmd );
#    $self->plan->task->logger_manager->run_info->job_id( $self->job_manager->job_id );
#    $self->plan->task->logger_manager->run_info->orig_cmd( $self->orig_cmd );
    $self->plan->task->logger_manager->init_logger;

    if ( $self->plan->settings->shell eq 'background' ){
        $self->run_info->shell('background');
        $self->job_manager->daemonize;
    }

    if ( $self->plan->settings->iterate eq 'repeat' ){

        while(1){
            $self->plan->run;
            sleep( $self->plan->settings->poll_interval );
        }

    } else {
        $self->plan->run;
    }

}

=head1 NAME

TaskPipe::Tool::Command_RunPlan - command to run a TaskPipe plan

=head1 PURPOSE

Execute the specified plan, or the default plan from configuration if no explicit C<--plan> option is provided

=head1 DESCRIPTION

C<run plan> executes the specified plan in accordance with the settings in your config. To run the default plan (usually C<plan.yml>) over the default project (as specified by the  C<project> parameter in the C<TaskPipe::PathSettings::Global> section of your config) simply type

    taskpipe run plan

To specify a particular plan include C<--plan>:

    taskpipe run plan --plan=specificplan.yml

To name a project other than the default, use

    taskpipe run plan --project=otherproject

To run the plan in the background use the C<--shell=background> parameter. To run it repeatedly use C<--iterate=repeat>. You can daemonize a process by combining the two:

    taskpipe run plan --shell=background --iterate=repeat

See L<OPTIONS> for more information.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3
=cut

__PACKAGE__->meta->make_immutable;
1;



