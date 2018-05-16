package TaskPipe::Task::ModuleMap;

use Moose;
use Carp;
use TaskPipe::PathSettings;
use Module::Runtime 'require_module';
use Try::Tiny;

with 'MooseX::ConfigCascade';

has path_settings => (is => 'ro', isa => 'TaskPipe::PathSettings', default => sub{
    TaskPipe::PathSettings->new;
});

has task_name => (is => 'rw', isa => 'Str');


sub load_module{
    my $self = shift;

    my $mod = $self->_get_mod_name( $self->path_settings->project->task_module_prefix );
    my @err;

    try {

        require_module( $mod );

    } catch {
        
        push @err, $_;
        my $tmod = $self->_get_mod_name( 'TaskPipe' );
        
        try {

            require_module( $tmod );

        } catch {

            push @err, $_;
            confess "Could not load a module for task_name ".$self->task_name." - module missing or broken. Tried to load $mod with result \"$err[0]]\" and $tmod with result \"$err[1]\". \@INC = @INC)"; 

        };
        $mod = $tmod;
    };

    return $mod;
    
}



sub _get_mod_name{
    my ($self,$prefix) = @_;

    my $mod = $prefix;
    $mod =~ s/::$//;
    $mod.= '::' if $mod;
    $mod.= $self->path_settings->project->task_identifier.$self->task_name;

    return $mod;
}


=head1 NAME

TaskPipe::Task::ModuleMap - map task names to modules

=head1 DESCRIPTION

Load and return the correct module associated with the task_name. This is used by L<TaskPipe::Task>. It is not recommended to use this module directly.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;

1;
