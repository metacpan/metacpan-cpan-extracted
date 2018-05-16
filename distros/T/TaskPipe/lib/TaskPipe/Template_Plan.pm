package TaskPipe::Template_Plan;

use Moose;
extends 'TaskPipe::Template';
with 'TaskPipe::Role::MooseType_ScopeMode';

has dir_label => (is => 'ro', isa => 'Str', default => 'plan');

sub target_filename{
    my ($self) = @_;

    return +$self->path_settings->project->plan;
}


=head1 NAME

TaskPipe::Template_Plan - the base class for plan templates

=head1 DESCRIPTION

The base class for plan templates

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

1;
    

