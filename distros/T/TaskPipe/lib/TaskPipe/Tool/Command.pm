package TaskPipe::Tool::Command;

use Moose;
use DateTime;
use TaskPipe::SchemaManager;
use TaskPipe::JobManager;
use TaskPipe::Tool::Options;
use Pod::Term;

with 'MooseX::ConfigCascade';

has run_info => (is => 'rw', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new;
});


has options => (is => 'rw', isa => 'TaskPipe::Tool::Options', default => sub{
    TaskPipe::Tool::Options->new;
});


has path_settings => (is => 'ro', isa => 'TaskPipe::PathSettings', default => sub{
    TaskPipe::PathSettings->new( scope => 'project' )
});


has job_manager => (is => 'ro', isa => 'TaskPipe::JobManager', lazy => 1, default  => sub{
    my ($self) = @_;
    
    my $project = '*global';
    if ( $self->run_info->scope eq 'project' ){
        $project = $self->path_settings->project_name;
    }

    if (! $project ){
        confess "[B<Attempted to start a project-related job, but no project name could be determined. Did you forget to include the> C<--project> B<parameter on the command line? Alternatively, specify a default project in the TaskPipe::PathSettings::Global section of your config:>

        project: myprojectname

]";
    }

    TaskPipe::JobManager->new(
        name => $_[0]->name,
        project => $project,
        shell => 'foreground',
        created_dt => DateTime->now
    );
});

sub name{ my ($n) = ref($_[0]) =~ /^${\__PACKAGE__}_(\w+)$/; $n; }

=head1 NAME

TaskPipe::Tool::Command - base class for TaskPipe Tool commands

=head1 DESCRIPTION

See individual <TaskPipe::Tool::Command_...> packages for information on specific commands. You should not use this class directly.

You can create a new tool command by inheriting from this class. However, this is not for the faint-hearted and not recommended if you don't fully understand TaskPipe architecture.

The inherited package should look like this:

    package TaskPipe::Tool::Command_NewCommand;
    use Moose;
    extends 'TaskPipe::Tool::Command';
    with 'MooseX::ConfigCascade';

    has option_specs => (is => 'ro', isa => 'ArrayRef', defaults => sub{[
        
        # which options are available for your command?
        # Enter settings attributes like this:
        {
            module: (name of module to take settings from)
            items: [
                # (arrayref of attributes to take from 
                # the module - or omit to take them all)
            ],
            is_config: 1 # Boolean. Are the settings taken
                            from this module available in config
                            or just on command line?
        },

        {
            # ...
        }

    ]});

    sub execute{
        my ($self) = @_;

        # execute the command here
        
    
    }

    1;

See the other C<TaskPipe::Tool::Command_> packages for examples of how to prepare a command.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
