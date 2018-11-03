package TaskPipe::UserAgentManager;

use Moose;
with 'MooseX::ConfigCascade';

use LWP::UserAgent;
use URI::Escape;
use Log::Log4perl;
use Try::Tiny;
use Carp qw(confess longmess);
use File::Spec;
use TaskPipe::UserAgentManager::CheckIPSettings;
use TaskPipe::UserAgentManager::Settings;
use Data::Dumper;
use Module::Runtime 'require_module';

has settings => (is => 'ro', isa => 'TaskPipe::UserAgentManager::Settings', lazy => 1, default => sub{
    TaskPipe::UserAgentManager::Settings->new;
});

has check_ip_settings => (is => 'ro', isa => 'TaskPipe::UserAgentManager::CheckIPSettings', default => sub{
    TaskPipe::UserAgentManager::CheckIPSettings->new;
});


has run_info => (is => 'rw', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new;
});


has ua_handler => (is => 'rw', isa => __PACKAGE__.'::UserAgentHandler', lazy => 1, default => sub{
    my $module = __PACKAGE__.'::UserAgentHandler';
    require_module( $module );
    my $handler = $module->new(
        gm => $_[0]->gm
    );
    return $handler;
});

has gm => (is => 'rw', isa => 'TaskPipe::SchemaManager');


sub init{}

sub check_ip{
    my $self = shift;

    my $logger = Log::Log4perl->get_logger;

    my $resp;
    my $ip;
    for my $i (1..$self->check_ip_settings->max_retries){
        ($ip,$resp) = $self->check_ip_attempt;
        last if $ip;
        $logger->debug("IP check #$i failed. Response: ".$resp->decoded_content );
        sleep($self->check_ip_settings->retry_delay);
    }

    if ( $ip ){
        $logger->debug("IP checked and found to be: $ip" );
    } else{
        $logger->warn("Could not get new IP details: ".$resp->status_line."\n");
    }
    return $ip;
}


sub check_ip_attempt{
    my $self = shift;

    my $logger = Log::Log4perl->get_logger;

    my $resp = $self->ua_handler->call('get',$self->check_ip_settings->url);
    my $regex_text = $self->check_ip_settings->regex;

    my $regex = qr/$regex_text/;
    my ($ip) = $resp->decoded_content =~ /$regex/s;

    return ($ip,$resp);

}


sub delay{
    my $self = shift;

    my $logger = Log::Log4perl->get_logger;

    my $delay = 0;
    $delay = $self->settings->delay_base + int( rand($self->settings->delay_max_rand) + 0.5 );

    if ($delay > 0){
        $logger->info("Sleeping for $delay secs...");
        sleep($delay);
    }
}



sub request{
    my ($self,$method,@params) = @_;

    #$self->mu->record("request: at start");
    my $logger = Log::Log4perl->get_logger;

    my @req_meths = @{$self->ua_handler->settings->request_methods};
    confess "invalid request method '$method'. Valid methods are: @req_meths" unless grep { $_ eq $method } @req_meths;

    #$self->mu->record("request: after req meths");

    $self->delay if $self->settings->delay_base || $self->settings->delay_max_rand;

    my $resp;
    #$self->mu->record("request: after delay");


    $self->before_request($method,@params);

    #$self->mu->record("request: after before_request");

    try {

        $resp = $self->ua_handler->call($method,@params);


    } catch {

        $logger->warn("->request returned an error: $_\nStacktrace: ".longmess(''));

    };

    #$self->mu->record("request: after call");

    $self->after_request($resp,$method,@params);

    #$self->mu->record("request: at end");

    #$logger->debug("MEM: ".$self->mu->report);

    return $resp;
}


sub before_request{}
sub after_request{} #override?

    

sub refresh{
    my $self = shift;

    #$self->ua_handler->ua( $self->ua_handler->build_ua );
    $self->ua_handler->clear_cookies;
}


sub clear_cookies{
    my ($self) = @_;

    $self->ua_handler->call( 'cookie_jar' => {} );

}

=head1 NAME

TaskPipe::UserAgentManager - base class for managing requests in TaskPipe

=head1 DESCRIPTION

You can use this class with L<TaskPipe::Task_Scrape> by specifying it as the useragent manager to use in your project config. The useragent handler module specified in the C<ua_handler_module> setting in your config should provide the useragent handler L<TaskPipe::UserAgentManager> will use. E.g.:

    TaskPipe::Task_Scrape::Settings:
        ua_mgr_module: TaskPipe::UserAgentManager
        ua_handler_module: TaskPipe::UserAgentManager::UserAgentHandler

        # ...

If you want to modify the way TaskPipe makes requests you can inherit from L<TaskPipe::UserAgentManager> and create your own UserAgentManager. The format for your custom useragent manager might be as follows:

    package TaskPipe::UserAgentManager_MyUAManager;    
    use Moose;

    sub init{
        my ($self) = @_;

        # do something on initialisation

    }


    sub before_request($self,method,@params){
    
        # method = 'get', 'post', ...
        # params = whatever params were passed when 
        #            the request was made (url etc)
        #
        # Do something directly before the request happens

    }
     

    sub after_request($self,$resp,$method,@params){

        # resp = the HTTP::Response object
        #
        # Do something directly after the request happens

    }

    __PACKAGE__->meta->make_immutable;
    1;

=head1 SEE ALSO

If you are thinking of inheriting from TaskPipe::UserAgentManager, see the modules included in C<TaskPipe> already for exmples of how to do this:

L<TaskPipe::UserAgentManager_ProxyNet>
L<TaskPipe::UserAgentManager_ProxyNet_TOR>
L<TaskPipe::UserAgentManager_ProxyNet_Open>

See L<TaskPipe::UserAgentManager::UserAgentHandler> for more information about handlers.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut
   

__PACKAGE__->meta->make_immutable;

1;



    
