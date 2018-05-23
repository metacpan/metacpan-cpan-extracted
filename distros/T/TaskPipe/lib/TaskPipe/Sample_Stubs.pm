package TaskPipe::Sample_Stubs;

use Moose;
extends 'TaskPipe::Sample';

has templates => (is => 'rw', isa => 'ArrayRef', default => sub{[
    'Config_Project',
    'Task_ScrapeStub',
    'Plan_Stub'
]});


has schema_templates => (is => 'rw', isa => 'ArrayRef', default => sub{[
    'Project'
]});

=head1 NAME

TaskPipe::Sample_Stubs - the default sample that is used when deploying files/db tables

=head1 DESCRIPTION

Essentially this is an empty sample, and is the default that is used when deploying files or tables for a new project. Including C<--sample=stubs> when deploying files or tables will have the same effect as omitting this parameter.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
