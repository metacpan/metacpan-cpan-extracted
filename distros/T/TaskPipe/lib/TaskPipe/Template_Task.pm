package TaskPipe::Template_Task;

use Moose;
use Template::Nest;
extends 'TaskPipe::Template';
with 'TaskPipe::Role::MooseType_ScopeMode';

has name => (is => 'ro', isa => 'Str');
has template_vars => (is => 'ro', isa => 'HashRef', lazy => 1, default => sub{
    my $p = $_[0]->path_settings->project;
    return {
        task_module_prefix => +$p->task_module_prefix,
        task_identifier => +$p->task_identifier,
        name => +$_[0]->name
    }
});


sub target_filename{
    my ($self) = @_;

    confess "name needs to be defined" unless $self->name;
    
    return +$self->path_settings->project->task_identifier.$self->name.'.pm';
}


sub target_dir{
    my ($self) = @_;

    return +$self->path_settings->path( 
        'lib',
        $self->path_settings->project->task_module_prefix
    );
}

=head1 NAME

TaskPipe::Template_Task - base class for task templates

=head1 DESCRIPTION

Base class for task templates

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut



1;
