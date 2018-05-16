package TaskPipe::UserAgentManager_ProxyNet_TOR;

use Moose;
use MooseX::ClassAttribute;
use Proc::ProcessTable;
use TaskPipe::UserAgentManager::UserAgentHandler;
use Log::Log4perl;
extends 'TaskPipe::UserAgentManager_ProxyNet';
with 'MooseX::ConfigCascade';




has rotate_ip => (is => 'ro', isa => 'Bool', lazy => 1, default => 1);

has tor_manager => (is => 'ro', isa => 'TaskPipe::TorManager', lazy => 1, default => sub{ 
    TaskPipe::TorManager->new(
        #thread_id => $_[0]->thread_id,
        gm => $_[0]->gm
        #job_id => $_[0]->job_id
    );
});

class_has initialized => (is => 'rw', isa => 'Bool');

has gm => (is => 'rw', isa => 'TaskPipe::SchemaManager');





sub init{
    my $self = shift;

    #$self->tor_manager->thread_id( $self->thread_id );
    $self->tor_manager->connect_socket;

    $self->ua_handler->call(
        'proxy',
        $self->tor_manager->settings->protocols,
        $self->tor_manager->url
    );

    if ( ! $self->initialized ){
        $self->initialized( 1 );
    }    
}




sub change_ip{
    my $self = shift;

    $self->tor_manager->change_ip;
    $self->set_max;
    $self->cur_rno(0);
    $self->ua_handler->clear_cookies;

}

=head1 NAME

TaskPipe::UserAgentManager_ProxyNet_TOR - useragent manager for making requests through TOR

=head1 DESCRIPTION

This is the useragent manager for making requests through the TOR network. You need to have TOR installed and set up on your system, and you should check the settings you have in your global config under the C<TaskPipe::TorManager::Settings> section make sense for your system.

You can use this class with L<TaskPipe::Task_Scrape> by specifying it as the useragent manager to use in your project config. 

    TaskPipe::Task_Scrape::Settings:
        ua_mgr_module: TaskPipe::UserAgentManager_ProxyNet_TOR
        # ...

=head1 SEE ALSO

L<TaskPipe::UserAgentManager>
L<TaskPipe::UserAgentManager_ProxyNet>
L<TaskPipe::UserAgentManager::UserAgentHandler>

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
__END__
