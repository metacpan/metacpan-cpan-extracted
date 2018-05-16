package TaskPipe::Template_Config_Global;

use Moose;
extends 'TaskPipe::Template_Config';


has filename_label => (is => 'ro', isa => 'Str', default => 'global');

has option_specs => (is => 'ro', isa => 'ArrayRef', default => sub{[
    {
        module => 'TaskPipe::PathSettings::Global',
        exclude => [
            'root_dir',
            'default_home_filename',
            'home_filename',
            'global_conf_filename',
            'system_conf_filename'
        ]
    },
    'TaskPipe::PathSettings::Project',
    'TaskPipe::SchemaManager::Settings_Global',
    'TaskPipe::JobManager::Settings',
    'TaskPipe::TorManager::Settings',
    'TaskPipe::OpenProxyManager::IPList_PremProxy::Settings',
    'TaskPipe::OpenProxyManager::IPList_Xroxy::Settings',
    'TaskPipe::OpenProxyManager::IPList_ProxyNova::Settings'
]});

=head1 NAME

TaskPipe::Template_Config_Global - template for the global config file

=head1 DESCRIPTION

Used to deploy the global config file. Its not recommended to use this package directly. See the general manpages for TaskPipe

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;
1;


