package TaskPipe::UserAgentManager_ProxyNet_Open;

use Moose;
use Log::Log4perl;
use Module::Runtime 'require_module';
use DateTime;
use TaskPipe::OpenProxyManager;
extends 'TaskPipe::UserAgentManager_ProxyNet';
with 'MooseX::ConfigCascade';

has url => (is => 'rw', isa => 'Str');
has ips => (is => 'rw', isa => 'ArrayRef');
has current_proxy => (is => 'rw', isa => 'DBIx::Class::Core');

has proxy_manager => (is => 'ro', isa => 'TaskPipe::OpenProxyManager', lazy => 1, default => sub{
    TaskPipe::OpenProxyManager->new(
        gm => $_[0]->gm
    )
});


has last_list_index => (is => 'rw', isa => 'Int', default => 0);

sub next_list_index{
    my ($self) = @_;

    my $li = $self->last_list_index;
    my $max_li = scalar(@{$self->proxy_manager->settings->ip_list_names}) - 1;
    $li++;
    $li = 0 if $li > $max_li;
}



sub init{
    my $self = shift;

    $self->change_ip;
}




sub change_ip{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;

    if ( $self->current_proxy ){
        $self->current_proxy->update({
            job_id => undef,
            thread_id => undef
        });
    }

    my $proxy = $self->proxy_manager->next_available_proxy;

    my $proxy_uri = $self->proxy_manager->settings->proxy_scheme."://".$proxy->ip.':'.$proxy->port;

    $self->ua_handler->call('proxy', $self->proxy_manager->settings->protocols, $proxy_uri );
    $self->current_proxy( $proxy );
    $self->current_proxy->update({
        job_id => $self->run_info->job_id,
        thread_id => $self->run_info->thread_id
    });

    $logger->debug("New Proxy $proxy_uri selected");
}



sub before_request{
    my ($self) = @_;

    $self->current_proxy->update({
        last_used_dt => DateTime->now
    });
}


sub after_request{
    my ($self,$resp) = @_;

    my $logger = Log::Log4perl->get_logger;

    if (! $resp->is_success || ! $resp->decoded_content){

        $logger->debug("Changing IP - Response failed: ".$resp->status_line);
        $self->current_proxy->update({
            status => 'dud'
        });
        $self->change_ip;

    }
}

=head1 NAME

TaskPipe::UserAgentManager_ProxyNet_Open - useragent manager for making requests through an open proxy network

=head1 DESCRIPTION

This useragent manager uses TaskPipe's open proxy management system to make requests. You need to have run

    taskpipe fetch open proxies

and also

    taskpipe test open proxies

before using this package. See the help for those commands for further information.

You can use this package with L<TaskPipe::Task_Scrape> by specifying it as the useragent manager to use in your project config. 

    TaskPipe::Task_Scrape::Settings:
        ua_mgr_module: TaskPipe::UserAgentManager_ProxyNet_Open
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
        



