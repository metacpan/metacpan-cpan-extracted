package TaskPipe::OpenProxyManager::IPList;

use Moose;
use Web::Scraper;
use TaskPipe::UserAgentManager_ProxyNet_TOR;
use Digest::MD5 'md5_hex';
use Log::Log4perl;
use Module::Runtime 'require_module';
use Data::Dumper;
use Carp;
use Try::Tiny;

with 'MooseX::RelClassTypes';
with 'MooseX::ConfigCascade';

has run_info => (is => 'rw', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new;
});

has gm => (is => 'rw', isa => 'TaskPipe::SchemaManager');

has list_name => (is => 'ro', isa => 'Str', default => sub{ 
    # I wanted to call this just 'name', but if called as such
    # method calls always return undef. Moose bug?

    my $self = shift;

    my $name = ref($self);
    my $package = __PACKAGE__;
    
    $name =~ s/^$package//;
    $name =~ s/^_//;
    return $name;
});

has settings => (
    is => 'rw',
    isa => __PACKAGE__.'::Settings',
    default => sub{
        my $module = __PACKAGE__.'::Settings';
        require_module( $module );
        $module->new;
    }
);


has list_settings => (
    is => 'ro', 
    isa => '{CLASS}::Settings'
);



has ua_mgr => (is => 'rw', isa => 'TaskPipe::UserAgentManager', lazy => 1, builder => 'build_ua_mgr');

sub build_ua_mgr{ 
    my $self = shift;

    try {

        my $ua_handler_mod = $self->list_settings->ua_handler_module;
        require_module( $ua_handler_mod );
        my $ua_handler = $ua_handler_mod->new(
            gm => $self->gm
        );

        my $ua_mod = $self->list_settings->ua_mgr_module;
        require_module( $ua_mod );   
        my $ua_mgr = $ua_mod->new(
            gm => $self->gm,
            ua_handler => $ua_handler
        );

        return $ua_mgr;
    
    } catch {

        confess "Error in build_ua_mgr: ".$_;

    };
}



sub fetch_proxies{
    my $self = shift;

    my $proxies = [];
    my $found = 0;

    my $tm = TaskPipe::ThreadManager->new(
        gm => $self->gm,
        name => "OpenProxy",
        max_threads => $self->settings->max_threads,
        forks => 0
    );

    my $finished = 0;
    $self->ua_mgr->init;
    my @page_index = @{$self->page_index};

    for my $i (0..$#page_index){
        $tm->execute( sub{
            $self->next_proxy_set( $page_index[$i] );
        }, $i + 1, $i == $#page_index );
    }

    $tm->wait_children;
}


sub next_proxy_set{
    my ($self, $page_i) = @_;

    my $logger = Log::Log4perl->get_logger;
    $self->ua_mgr( $self->build_ua_mgr );
    $self->ua_mgr->init;

    my $url = $self->url_from_page_index( $page_i );      
    my $resp = $self->ua_mgr->request('get', $url );
    
    my $ip_ports;
    if ( $resp && $resp->is_success ){

        $ip_ports = $self->get_ip_ports( $resp->decoded_content, $url );

        if ( $ip_ports && @$ip_ports ){
            $self->insert_ip_ports( $ip_ports );
            $logger->debug($self->list_name.": found ".scalar(@$ip_ports)." on page $page_i: ".Dumper( $ip_ports ) );
        }

    }

    my $finished = $self->is_finished( $resp, $ip_ports );
    
    if (! $finished && ( ! $resp || ! $resp->is_success ) ){
        $self->ua_mgr->change_ip if $self->ua_mgr->can('change_ip');
    }

    $logger->debug("next_proxy_set finished: ".$finished);
    return $finished;
}

   


sub is_finished{
    my ($self,$resp,$ip_ports) = @_;

    my $finished = 0;
    if ( ($resp && $resp->status_line =~ /^404/ )
        || ! $ip_ports 
        || ! @$ip_ports
    ){
        $finished = 1;
    }

    return $finished;
}



sub page_index{
    my ($self) = @_;

    my $resp;
    my $count = 0;
    my $page_index_url = $self->page_index_url;
    do {
        $resp = $self->ua_mgr->request('get', $page_index_url );
        $count++;
    
    } while ( ! $resp->is_success && $count < $self->settings->max_retries );

    return [] unless $resp->is_success;

    my $page_index = $self->scrape_page_index( $resp, $page_index_url );

    return $page_index;

}



sub scrape_page_index{
    my ($self,$resp,$url) = @_;

    my $last_page_index = $self->last_page_index_ws->scrape( 
        $resp->decoded_content, 
        $url
    );

    my $page_index = $last_page_index ? [1..$last_page_index] : [];
    return $page_index;
}




sub get_ip_ports{
    my ($self, $content, $ref_url) = @_;

    my $ip_ports = $self->ws->scrape( $content, $ref_url );

    return $ip_ports;
}


sub insert_ip_ports{
    my ($self,$ip_ports) = @_;

    my $proxies = [];
    foreach my $ip_port ( @$ip_ports ){
        $ip_port->{ip} =~ s/^\s*//;
        $ip_port->{ip} =~ s/\s*$//;
        $ip_port->{port} ||= $self->settings->default_port;
        $ip_port->{port} =~ s/^\s*//;
        $ip_port->{port} =~ s/\s*$//;            

        next unless $ip_port->{ip} 
            && $ip_port->{ip} =~ /^\d+\.\d+\.\d+\.\d+$/ 
            && $ip_port->{port} 
            && $ip_port->{port} =~ /^\d+$/;

        my $open_proxy_row = $self->gm->table('open_proxy')->find_or_create({
            ip => $ip_port->{ip},
            port => $ip_port->{port},
            list_name => $self->list_name,
            status => 'untested'
        },{
            key => 'primary'
        });
    }
}

=head1 NAME

TaskPipe::OpenProxyManager::IPList - the base class for IPLists

=head1 DESCRIPTION

TaskPipe's Open Proxy system grabs Lists of open proxy IPs that are available on the internet. Inherit from this class to create a new list. The format of the inherited package is normally:

    package TaskPipe::OpenProxyManager::IPList_NewList;
    use Moose;
    use Web::Scraper
    extends 'TaskPipe::OpenProxyManager::IPList';

    has page_index_ws => (is => 'ro', isa => 'Web::Scraper', default => sub{
        scraper => {
            
            # define scraper to scrape page index of pages
            # which have the ips on
        
        }
    });

    has ws => (is => 'ro', isa => 'Web::Scraper', default => sub{
        scraper => {

            # define scraper to pull the ips from each list page
            # (return an arrayref)

        }
    });

    sub page_index_url{
        my ($self) = @_;

        # return the url of the page index
        # (define it in a ::Settings package?)

    }


    sub url_from_page_index{
        my ($self,$index_value) = @_;

        # turn index_value into the url for 
        # the list page and return it

    });

    ;

See the other C<TaskPipe::IPList_> packages for examples

=cut


1;
