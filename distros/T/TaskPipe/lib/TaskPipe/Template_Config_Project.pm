package TaskPipe::Template_Config_Project;

use Moose;
with 'TaskPipe::Role::MooseType_ScopeMode';

extends 'TaskPipe::Template_Config';

has option_specs => (is => 'ro', isa => 'ArrayRef', default => sub{[
    {
        module => 'TaskPipe::PathSettings::Project',
        items => [
            'plan',
            'task_module_prefix'
        ]
    },
    'TaskPipe::Task::Settings',
    'TaskPipe::Task::TestSettings',
    'TaskPipe::SchemaManager::Settings_Project', {
        module => 'TaskPipe::LoggerManager::Settings',
        exclude => [
            'log_screen_colors'
        ]
    }, {
        module => 'TaskPipe::ThreadManager::Settings',
        exclude => [
            'thread_table_deadlock_retries'
        ]
    },
    'TaskPipe::UserAgentManager::Settings', {
        module => 'TaskPipe::UserAgentManager::UserAgentHandler::Settings',
        exclude => [
            'request_methods'
        ]
    },
    'TaskPipe::UserAgentManager::CheckIPSettings',
    'TaskPipe::Task_Scrape::Settings',
    'TaskPipe::Plan::Settings'
]});

=head1 NAME

TaskPipe::Template_Config_Project - template for the project config

=head1 DESCRIPTION

This is the template which is used to deploy the project config. Its not recommended to use this template directly. See the general manpages for TaskPipe.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;
1;

