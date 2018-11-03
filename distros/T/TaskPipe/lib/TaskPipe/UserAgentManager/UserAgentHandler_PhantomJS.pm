package TaskPipe::UserAgentManager::UserAgentHandler_PhantomJS;

use Moose;
use Encode;
use WWW::Mechanize::PhantomJS;
use Module::Runtime 'require_module';
use Log::Log4perl;
use Try::Tiny;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Web::Scraper;
use TaskPipe::PortManager;

with 'MooseX::ConfigCascade';
extends 'TaskPipe::UserAgentManager::UserAgentHandler';

# Note: WWW::Mechanize::PhantomJS, Selenium::Remote::Driver (which
# WWW::Mechanize::PhantomJS uses) and PhantomJS all have individual
# problems. 2 specific ones to be aware of before changing this module:
#
# - the 'content_encoding()' method in WWW::Mechanize::PhantomJS seems to return 
#   Content-Type not Content-Encoding
# - there appears to be a bug in PhantomJS (see here: 
#   https://github.com/ariya/phantomjs/issues/13621) which means "Accept-Encoding" 
#   needs to be set using a particular format of js, and thus the 'add_header' method
#   in WWW::Mechanize::PhantomJS cannot be used. This module uses its own method

has phantom_settings => (is => 'rw', isa => __PACKAGE__.'::Settings', default => sub{
    my $module = __PACKAGE__.'::Settings';
    require_module( $module );
    $module->new;
});

has port_manager => (is => 'ro', isa => 'TaskPipe::PortManager', lazy => 1, default => sub{
    my ($self) = @_;

    TaskPipe::PortManager->new(
        process_name => $self->phantom_settings->process_name,
        base_port => $self->phantom_settings->base_port,
        gm => $self->gm
    );
});


has poll_for => (is => 'rw', isa => 'ArrayRef[Str]', default => sub{[]});

sub build_ua{
    my ($self) = @_;

    my $logger = Log::Log4perl->get_logger;

    my $port = $self->port_manager->get_port;
    my $ua = WWW::Mechanize::PhantomJS->new(
        port => $port
    );

    # WWW::Mechanize::PhantomJS does not seem to provide a method for
    # returning the pid of the phantomjs instance. However, it's
    # retrievable via $ua->{pid} (ugly, but.. unlikely to change?)
    $logger->debug("Started PhantomJS process with pid ".$ua->{pid}." on port $port");

    $self->gm->table('spawned')->update_or_create({
        process_name => $self->phantom_settings->process_name,
        thread_id => $self->run_info->thread_id,
        job_id => $self->run_info->job_id,
        used_by_pid => $$,
        pid => $ua->{pid},
        port => $port
    });

    my $timeout = $self->settings->timeout * 1000;

    try {
        $ua->eval_in_phantomjs("
            var page = this;
            page.settings.userAgent = ${\$self->settings->agent};
            page.settings.resourceTimeout = $timeout;
        ");
        
        foreach my $header_name ( keys %{$self->settings->headers} ){

            my $header_val = $self->settings->headers->{$header_name};

            $ua->eval_in_phantomjs( qq|
                var page = this;
                page.customHeaders["$header_name"] = "$header_val";
            |);
        };

        $ua->driver->debug_on if $self->phantom_settings->debug;

    } catch {

        confess "Error connecting to PhantomJS: ".$_;

    };

    return $ua;
}


sub call{
    my ($self,$method,@params) = @_;

    my $resp;

    try {

        if ( grep { $_ eq $method } @{$self->settings->request_methods} ){


            $resp = $self->request($method,@params);


        } elsif ( $method eq 'proxy' ){

            $resp = $self->set_proxy(@params);

        } elsif ( $method eq 'default_header' ){

            $resp = $self->default_header( @params );

        } elsif ( $method eq 'default_headers' ){

            $resp = $self->default_headers;

        } else {

            $resp = $self->SUPER::call( $method, @params );

        }

    } catch {

        confess "PhantomJS call failed: $_";

    };


    return $resp;
}


sub set_proxy{
    my ($self,$protocols,$url) = @_;

    my $logger = Log::Log4perl->get_logger;

    my ($scheme,$host,$port) = $url =~ m{^([^:]+)://([^:]+):([^:]+)$};

    $logger->debug("in set_proxy scheme=$scheme port=$port host=$host");

    my $type = $self->phantom_settings->proxy_schemes->{ $scheme };
    confess "attempt to set proxy with unrecognised scheme '$scheme'" unless $type;

    try {
        $self->ua->eval_in_phantomjs( qq|
            var page = this;
            phantom.setProxy("$host","$port","$type");
        |);
    } catch {
        "PhantomJS error setting proxy: $_";
    };
}


sub default_header{
    my ($self,$header_name,$header_val) = @_;

    confess "header_name is required" unless $header_name;

    if ( $header_val ){

        $self->ua->eval_in_phantomjs( qq|
            var page = this;
            page.customHeaders["$header_name"] = "$header_val";
        |);

    } else {

        my $js = qq|
            return this.customHeaders["$header_name"];
        |;

        $header_val = $self->ua->eval_in_phantomjs( $js );
    
    }

    return $header_val;
}



sub default_headers{
    my ($self) = @_;

    my $js = qq|
        return this.customHeaders;
    |;

    return $self->ua->eval_in_phantomjs( $js );
}



sub request{
    my ($self,$method,@params) = @_;

    my @req_meths = @{$self->settings->request_methods};
    confess "invalid request method '$method'. Valid methods are: @req_meths" unless grep { $_ eq $method } @req_meths;

    my $resp = $self->SUPER::call( $method, @params );
    $resp->remove_header( "Content-Encoding" );
    usleep ( $self->phantom_settings->page_load_wait_time * 1000 );
    
    my $content = $self->ua->driver->get_page_source;

    my @poll_for = @{$self->poll_for};

    if ( @poll_for ){
        my $elapsed = 0;
        my $t0 = [ gettimeofday ];
        while ( $elapsed < $self->phantom_settings->poll_for_timeout ){
            my $success = 1;
            foreach my $poll_item (@poll_for){
                my $ws = scraper{
                    process_first $poll_item, 'poll_item' => 'RAW';
                    result 'poll_item';
                };
                my $poll_res = $ws->scrape($content);
                if ( ! $poll_res ){
                    $success = 0;
                    last;
                }
            }
            print "elapsed $elapsed success $success\n";
            last if $success;
            usleep( $self->phantom_settings->poll_for_interval );
            $elapsed = 1000 * tv_interval( $t0, [ gettimeofday ] );
            $content = $self->ua->driver->get_page_source;
        }
    }
            
    $resp->content( encode("utf8",$content ) );
    
    return $resp;
}


sub clear_cookies{
    my ($self) = @_;

    try {
        $self->ua->eval_in_phantomjs( qq| phantom.clearCookies(); | );
    } catch {
        confess "PhantomJS Clear cookies error: $_";
    };
}
       
=head1 NAME

TaskPipe::UserAgentManager::UserAgentHandler_PhantomJS - useragent handler for phantomjs

=head1 DESCRIPTION

This is the useragent handler module for PhantomJS. You can tell L<TaskPipe::Task_Scrape> to use this module, by specifying

    ua_handler_module: TaskPipe::UserAgentManager::UserAgentHandler_PhantomJS

in the L<TaskPipe::Task_Scrape::Settings> section of the project config

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
