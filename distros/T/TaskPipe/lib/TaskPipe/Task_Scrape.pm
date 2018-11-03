package TaskPipe::Task_Scrape;

use Moose;
use Carp;
use URI;
use Data::Dumper;
use DateTime;
use Log::Log4perl;
use Module::Runtime qw(require_module);
use Cwd 'abs_path';
use File::Basename;
use TaskPipe::Task_Scrape::Settings;

extends 'TaskPipe::Task';
with 'MooseX::ConfigCascade';


has scrape_settings => (is => 'ro', isa => __PACKAGE__.'::Settings', default => sub{
    my $module = __PACKAGE__.'::Settings';
    require_module( $module );
    $module->new;
});

has ua_mgr => (is => 'rw', isa => 'TaskPipe::UserAgentManager', lazy => 1, default => sub{ 
    my ($self) = @_;

    my $ua_handler_mod = $self->scrape_settings->ua_handler_module;
    require_module( $ua_handler_mod );
    my $ua_handler = $ua_handler_mod->new( 
        gm => $self->gm
    );
    $ua_handler->poll_for( $self->poll_for ) if $self->can('poll_for') && $ua_handler->can('poll_for');

    my $ua_mod = $self->scrape_settings->ua_mgr_module;
    require_module( $ua_mod );   
    my $ua_mgr = $ua_mod->new(
        gm => $self->gm,
        ua_handler => $ua_handler
    );
    $ua_mgr->init;

    return $ua_mgr;
});

has run_info => (is => 'rw', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new;
});

has url => (is => 'rw', isa => 'Str');
has page_content => (is => 'rw', isa => 'Str');
has status => (is => 'rw', isa => 'Str');




sub scrape{
    my ($self) = @_;

    #$self->log_mem("Top of scrape                       ");
    my $scraped = $self->ws->scrape( $self->page_content, $self->url ) || [];
    #$self->log_mem("After ws scrape                     ");
    $scraped = $self->post_process( $scraped ) if $self->can('post_process');
    #$self->log_mem("After post process                  ");
    confess "->ws should return an array ref, but instead returned a ".ref( $scraped ) unless ref( $scraped ) =~ /array/i;
    
    return $scraped;
}


sub _verbose_fail{
    my ($self,$msg) = @_;

    my $fail_msg = $self->run_info->as_string.": ".$msg." Inputs: ".Dumper( $self->input )."\nInput History: ".Dumper( $self->input_history );
    confess $fail_msg;
}


sub action{
    my ($self) = @_;

    #$self->log_mem("Top of action                       ");
    my $logger = Log::Log4perl->get_logger;  

    if ( ! $self->pinterp->{url} ){
        $self->_verbose_fail("url required but none provided") if $self->scrape_settings->require_url;
        return [];
    }


    $self->url( $self->pinterp->{url} );
    $logger->info("Getting ".$self->pinterp->{url});

    if ( $self->pinterp->{page_content} ){
    
        $self->page_content( $self->pinterp->{page_content} )

    } else {

        $self->request_page_content;

    }

    #$self->log_mem("After request page content          ");

    my $scraped = $self->scrape;

    #$self->log_mem("After scrape                        ");

    my $tries = 0;

    while( $self->url && $self->retry_condition( $scraped ) && $tries < $self->scrape_settings->max_retries ){
        #$self->ua_mgr->refresh;
        $self->request_page_content;
        $scraped = $self->scrape;
        $tries++;
        $logger->debug("Retry $tries");

    }

    $self->_verbose_fail("Fail condition persisted despite ".$self->scrape_settings->max_retries." retry attempts") if $self->fail_condition( $scraped );

    $self->ws( undef ) if defined $self->ws;
    $self->page_content('');
    #$self->log_mem("End of sub                          ");
    return $scraped;
}


sub retry_condition{ #override in child?
    my ($self,$scraped) = @_;
    return 1 unless $self->status =~ /^200/;
    my $retry = 1;
    $retry = 0 if $scraped && @$scraped;
    return $retry;
}

sub fail_condition{
    my ($self,$scraped) = @_;
    return 1 unless $self->status =~ /^200/;

    my $fail = 1;
    $fail = 0 if $scraped; # && @$scraped;
    return $fail;
}

sub request_page_content{
    my ($self) = @_;

    #$self->log_mem("top of request_page_content sub     ");
    #$self->mu->record("request_page_content: at start") if $self->can('mu');
    my $logger = Log::Log4perl->get_logger;

    my $headers = $self->pinterp->{headers} || {};

    if ( $self->scrape_settings->require_referer && ! $headers->{Referer} ){

        $self->_verbose_fail("Cannot make request: No Referer");

    }

    #$self->mu->record("request_page_content: before set headers") if $self->can('mu');
    foreach my $header_name ( keys %$headers ){ 
        $self->ua_mgr->ua_handler->call('default_header',$header_name, $headers->{$header_name});
    }

    #$self->log_mem("After default headers               ");

    #$self->mu->record("request_page_content: before get") if $self->can('mu');
    my $content;
    my $resp = $self->ua_mgr->request( 'get', $self->url );
    #$self->mu->record("request_page_content: after get") if $self->can('mu');

    #$self->log_mem("After request                       ");
    if ( ! $resp || ! $resp->is_success ){

        my $message = "Request to ".$self->url." failed. ";
        $message.="No response was returned" unless $resp;
        $message.="Response was: ".$resp->status_line if $resp;
        $logger->warn( $message );

    } else {

        $content = $resp->decoded_content;
                    
    }

    #$self->log_mem("After test resp                     ");
    #$self->mu->record("request_page_content: after is_success") if $self->can('mu');

    if ( $content ){
        $self->page_content( $content );
    } else {
        $self->page_content( '' );
    }

    my $status = '400';
    $status = $resp->status_line if $resp;
    $self->status( $status );
    #$self->mu->record("request_page_contetn: at end") if $self->can('mu');
    #$self->log_mem("End of request_page_content sub     ");

}



sub add_test_output{
    my ($self) = @_;

    my $output = "=== Page Content Follows ===\n\n";
    $output.= $self->page_content."\n\n";
    $output.= "=== End of Page Content ===\n";
    return $output;

}

=head1 NAME

TaskPipe::Task_Scrape - Base TaskPipe class for scraping a webpage

=head1 DESCRIPTION

This is the standard building block for creating a webpage-scraping task. To do this inherit from L<Task::Scrape> using the following package format:

    package TaskPipe::Task_Scrape_MyScraper;

    use Moose;
    use Web::Scraper;
    extends 'TaskPipe::Task_Scrape';

    has test_pinterp => (is => 'ro', isa => 'ArrayRef[HashRef], default => sub{[

        {
            url => 'https://www.example.com/some-test-url',
            headers => {
                Referer => 'https://www.example.com/some-referer-url'
            }
        }
    
    ]});


    has ws => (is => 'ro', isa => 'Web::Scraper', default => sub{
        scraper {
            process 'div.some-class', 'results' => 'TEXT';
            result 'results'
        }
    });

    sub post_process {  # may or may not be necessary, depending
                        # on what is returned by ws
 
        my ($self,$results) = @_;

        # do something with the results returned from the web scraper

        return $results;
    }
    
C<test_pinterp> allows you to specify test data which you can run the task against by typing

    taskpipe test task --name=Scrape_MyScraper

at the command line. 

It is assumed you want to use a L<Web::Scraper> to scrape your page. If this is the case, just define a C<ws> attribute as above. See the L<Web::Scraper> manpage for more information on how to define a L<Web::Scraper>.

Your task needs to return an arrayref of results (each result being a hashref). It's great if you can get C<ws> to return this directly. Sometimes it is not possible to persuade your L<Web::Scraper> to return results in this format. To make format corrections (remove records from the data etc) you can include a C<post_process> subroutine. C<post_process> receives the output from ws. Do what is needed, and make sure you return your C<results> arrayref at the end.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;

      
