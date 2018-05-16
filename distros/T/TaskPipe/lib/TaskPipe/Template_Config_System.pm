package TaskPipe::Template_Config_System;

use Moose;
extends 'TaskPipe::Template_Config';

has filename_label => (is => 'ro', isa => 'Str', default => 'system');

has option_specs => (is => 'ro', isa => 'ArrayRef', default => sub{[
    "TaskPipe::PodReader::Settings"
]});

=head1 NAME

TaskPipe::Template_Config_System - the template package for the 'system' config file

=head1 DESCRIPTION

This is the package which is used to deploy the 'system' global config file. It is not recommended to use this package directly. See the general manpages for TaskPipe

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
   
