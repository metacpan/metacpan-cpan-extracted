package TaskPipe::OpenProxyManager;

use Moose;
use Carp;
use Log::Log4perl;
use DateTime;
use Module::Runtime 'require_module';
use Digest::MD5 qw(md5_base64);
use TaskPipe::UserAgentManager;
use TaskPipe::ThreadManager;
with 'MooseX::ConfigCascade';


has gm => (is => 'rw', isa => 'TaskPipe::SchemaManager');

has my_ip => (is => 'rw', isa => 'Str', lazy => 1, default => sub{
    my $self = shift;

    my $ua_mgr = TaskPipe::UserAgentManager->new(
        gm => $self->gm
    );
    my $ip = $ua_mgr->check_ip;
    return $ip;
});


has ua_mgr => (is => 'ro', isa => 'TaskPipe::UserAgentManager', lazy => 1, default => sub{
    TaskPipe::UserAgentManager->new(
        gm => $_[0]->gm
    );
});


has settings => (is => 'rw', isa => __PACKAGE__.'::Settings', default => sub{
    my $module = __PACKAGE__.'::Settings';
    require_module( $module );
    $module->new;
});


has lists => (is => 'ro', isa => 'ArrayRef', lazy => 1, default => sub{
    my $self = shift;
    my $seen = {}; #guard against duplicate entries in list

    my $lists = [];
    foreach my $list_name ( @{$self->settings->ip_list_names} ){
        next if $seen->{$list_name};

        my $mod = __PACKAGE__.'::IPList_'.$list_name;
        require_module( $mod );

        my $list = $mod->new( 
            gm => $self->gm
        );

        push @$lists,$list;
        $seen->{$list_name} = 1;
    }

    return $lists;
});





sub fetch_proxies{
    my $self = shift;

    my $logger = Log::Log4perl->get_logger;

    my $tm = TaskPipe::ThreadManager->new(
        gm => $self->gm,
        name => "OpenProxy",
        max_threads => $self->settings->max_threads,
        forks => 0
    );

    $tm->init;

    my $count = 0;
    my @lists = @{$self->lists};
    for my $list_i (0..$#lists){

        my $list = $lists[$list_i];
        my $list_name = $list->list_name;

        $list->fetch_proxies;

    }

    $tm->wait_children;
    $tm->finalize;
}




sub test_proxy{
    my ($self,$proxy) = @_;

    my $logger = Log::Log4perl->get_logger;

    my $uri = $self->settings->proxy_scheme.'://'.$proxy->ip.':'.$proxy->port;
    $logger->debug("Open proxy checker: Testing proxy $uri");

    my $ua_mgr = TaskPipe::UserAgentManager->new(
        gm => $self->gm
    );

    $ua_mgr->ua_handler->call( 'proxy', $self->settings->protocols => $uri );

    my $ip = $ua_mgr->check_ip;
    $logger->debug("ip [$ip] my ip [".$self->my_ip."]") if $ip;

    my $success = 0;
    if ( $ip ){
        $logger->debug("Successful response from proxy $uri");
        
        if ( $ip ne $self->my_ip ){
            $logger->debug("Proxy $uri does not project originating IP - test successful");
            $success = 1;
        } else {
            $logger->debug("Proxy $uri seems to project originating IP - test failed");
        }
    } 

    my $status = $success ? 'available' : 'dud';

    my $dt = DateTime->now;

    $proxy->update({
        checked_dt => $dt,
        status => $status
    });

    return $success;

}



sub test_proxies{
    my $self = shift;

    my $logger = Log::Log4perl->get_logger;

    my $dt = DateTime->now->subtract( minutes => 10 );
    my $dud_dt = DateTime->now->subtract( days => +$self->settings->clean_dud_proxies_after );

    my $dtp = $self->gm->schema->storage->datetime_parser;

    $self->gm->table('open_proxy')->search({ 
        checked_dt => { '<', +$dtp->format_datetime( $dud_dt ) },
        status => 'dud'
    })->delete_all;

    my $proxy_rs = $self->gm->table('open_proxy')->search([{
        checked_dt => undef
    }, {
        checked_dt => { '<', $dtp->format_datetime( $dt ) },
        status => { '!=', 'dud' }
    }], {
        order_by => { -asc => 'checked_dt' }
    });
    
    my $tm = TaskPipe::ThreadManager->new(
        gm => $self->gm,
        name => "OpenProxy",
        max_threads => $self->settings->max_threads,
        forks => 0
    );

    $tm->init;

    my $count = 0;
    my $total = $proxy_rs->count;

    while( my $proxy = $proxy_rs->next ){
        $count++;

        $tm->execute( sub{    
                #my ($thread_id) = @_;
                $self->test_proxy( 
                    #$thread_id,
                    $proxy
                );
            },
            $count,
            $count == $total
        );        
    }

    $tm->wait_children;
    $tm->finalize;    
}


sub next_available_proxy{
    my $self = shift;

    my $logger = Log::Log4perl->get_logger;
    my $proxy = $self->next_available_proxy_attempt;

    my $fails = 0;
    while ( ! $proxy ){
        $fails++;
        confess "Failed to find an available proxy on ".$self->settings->max_unavailable_fails." attempts" if ( $self->settings->max_available_fails >= $fails );
        $logger->warn("No proxy appears to be available. Waiting ".$self->settings->unavailable_poll_interval." seconds");
        sleep( $self->settings->unavailable_poll_interval );
        $proxy = $self->next_available_proxy_attempt;
    }

    return $proxy;
}
    



sub next_available_proxy_attempt{
    my $self = shift;

    my $reserve_id = "reserved-".md5_base64( $$ * rand );

    $self->gm->schema->txn_do( sub{
        my $rs = $self->gm->table('open_proxy')->search({
            status => 'available'
        },
        { 
            rows => 1,
            'for' => 'update',
            order_by => { -asc => 'last_used_dt' }
        });
        $rs->update({
            status => $reserve_id
        });
    });

    my $proxy = $self->gm->table('open_proxy')->find({
        status => $reserve_id
    });

    if ( $proxy ){
        $proxy->update({
            last_used_dt => DateTime->now,
            status => 'available'
        });
    }

    return $proxy;
}

=head1 NAME

TaskPipe::OpenProxyManager - open proxy management for TaskPipe

=head1 DESCRIPTION

It is not recommended to use this module directly. See the general manpages for TaskPipe

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1; 




 
