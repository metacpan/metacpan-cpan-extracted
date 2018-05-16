package TaskPipe::Tool::Command_StopJob;

use Moose;
use TaskPipe::JobManager;
use Carp;
use DateTime;
extends 'TaskPipe::Tool::Command';


has option_specs => (is => 'ro', isa => 'ArrayRef', default => sub{[{
    module => __PACKAGE__,
    is_config => 0
}]});

has job_manager => (is => 'ro', isa => 'TaskPipe::JobManager', lazy => 1, default  => sub{
    TaskPipe::JobManager->new(
        name => $_[0]->name,
        project => '*global',
        shell => 'foreground'
    );
});



sub execute{
    my $self = shift;

    $self->run_info->scope( 'global' );
    confess "job_id must be provided" unless $self->job_id;
    $self->job_manager->stop_job( $self->job_id );

}

=head1 NAME

TaskPipe::Tool::Command_StopJob - command to stop a running taskpipe job

=head1 PURPOSE

Stop a TaskPipe process. Usually you want to do this because you started a job in the background (using the C<--shell=background> parameter).

=head1 DESCRIPTION

For example if earlier you executed the command

    taskpipe run plan --shell=background

and you wanted to stop that job then you should first run

    taskpipe show jobs

use the list which is returned to identify the job id corresponding to the C<run plan> command, then type

    taskpipe stop job --job_id=<insert job id>

Using C<stop job> rather than manually killing processes is recommended where possible, because jobs can involve multiple threads and subprocesses (such as TOR instances) which C<stop job> will attempt to identify and shut down appropriately.


=head1 OPTIONS

=over

=item job_id

The ID of the job you want to stop. To find the C<job_id>, use C<show jobs>.

=cut

has job_id => (is => 'ro', isa => 'Str');

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;
1;  
