package TaskPipe::Tool::Command_DeployFiles;

use Moose;
use Carp;
use Try::Tiny;
use TaskPipe::FileInstaller;
use TaskPipe::Template_Config_Project;
use Module::Runtime 'require_module';

extends 'TaskPipe::Tool::Command';

has option_specs => (is => 'ro', isa => 'ArrayRef', default => sub{[{
    module => __PACKAGE__,
    items => [
        'sample'
    ]
}, {
    module => 'TaskPipe::PathSettings::Global',
    items => [
        'project_root',
        'project',
    ],
    is_config => 1
}, {
    module => 'TaskPipe::PathSettings::Project',
    items => [
        'lib_dir',
        'plan_dir',
        'source_dir',
        'log_dir'
    ],
    is_config => 1
}]});



sub execute {
    my ($self) = @_;

    my $module = 'TaskPipe::Sample_'.ucfirst($self->sample);
    require_module( $module );

    my $sample = $module->new;

    $sample->deploy_files;
}

=head1 NAME

TaskPipe::Tool::Command_DeployFiles - command to deploy TaskPipe project files

=head1 PURPOSE

When creating a new project, run this command first to deploy project directory structure and file stubs.

=head1 DESCRIPTION

C<deploy files> is the first step in creating a new project. You need to supply the C<--project=myproject> parameter on the command line. C<deploy files> then creates a directory with the project name you specified (C</myproject> in our example), and the subdirectories such as C<lib>, C<logs> and C<conf>.

A project config file is deployed into the project config dir (usually C</conf> unless you specified otherwise), which you need to edit before deploying cache tables (see the help for C<deploy tables>.) For example, if you installed TaskPipe in the sub-directory C</taskpipe> inside your home directory, and your project is called C<myproject> then the path to your project config should be

    ~/taskpipe/projects/myproject/conf/project.yml

In particular, the database parameters (database name, host etc.) need to be filled in correctly before you will be able to issue any commands associated with the new project. (Look for parameter values that have a tilde C<~> in the new config file).

=head1 OPTIONS

=over

=item sample

The name of the sample to use to deploy files

=cut

has sample => (is => 'ro', isa => 'Str', default => 'stubs');


=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;
1;
