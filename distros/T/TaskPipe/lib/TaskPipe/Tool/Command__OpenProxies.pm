package TaskPipe::Tool::Command__OpenProxies;

use Moose;
use MooseX::ClassAttribute;
extends 'TaskPipe::Tool::Command';
with 'MooseX::ConfigCascade';

use TaskPipe::OpenProxyManager;

has schema_manager => (is => 'rw', isa => 'TaskPipe::SchemaManager', lazy => 1, default => sub{
    my $sm = TaskPipe::SchemaManager->new;
    $sm->connect_schema;
    return $sm;
});


class_has option_specs => (is => 'ro', isa => 'ArrayRef', default => sub{[{
    module => 'TaskPipe::OpenProxyManager::Settings',
    is_config => 1
}]});


has proxy_manager => (is => 'ro', isa => 'TaskPipe::OpenProxyManager', lazy => 1, default => sub{
    TaskPipe::OpenProxyManager->new( 
        gm => $_[0]->schema_manager
    );
});

has job_manager => (is => 'ro', isa => 'TaskPipe::JobManager', lazy => 1, default  => sub{
    TaskPipe::JobManager->new(
        name => $_[0]->name,
        project => '*global'
    );
});


sub execute{
    my $self = shift;

    $self->run_info->scope( 'global' );

    if ( $self->proxy_manager->settings->shell eq 'background' ){
        $self->run_info->shell('background');
        $self->job_manager->daemonize;
    }
    
    my $repeat = $self->proxy_manager->settings->iterate eq 'repeat'?1:0;

    do {
        $self->execute_specific;
    } while ( $repeat );
}

sub execute_specific{

    confess "Override in child";

}

=head1 NAME

TaskPipe::Tool::Command__OpenProxies - base calss for open proxy related commands

=head1 DESCRIPTION

This is the base class for commands related to open proxies (fetch open proxies and test open proxies both inherit from this class). 

Note the double underscore __ in the name tells L<TaskPipe::Tool> this is a base class and to ignore it from the commands list.

It is not recommended to use this class directly. 

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut



__PACKAGE__->meta->make_immutable;

1;
