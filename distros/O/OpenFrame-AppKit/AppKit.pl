#!/usr/bin/perl

##
## simple openframe server
##

use lib './lib', '../openframe3/lib';
use strict;
use warnings;

use Pipeline;
use HTTP::Daemon;
use OpenFrame::AppKit;
use OpenFrame::Segment::HTTP::Request;
use OpenFrame::AppKit::Examples::Hangman;
use OpenFrame::AppKit::Examples::NameForm;

my $d = HTTP::Daemon->new( LocalPort => '8080', Reuse => 1);
die $! unless $d;

print "server running at http://localhost:8080/\n";

## wait for connections
while(my $c = $d->accept()) {
  ## get requests of the connection
  while(my $r = $c->get_request) {
    ## create a new Pipeline object
    my $pipeline = Pipeline->new()->debug(1);

    ##
    ## create the segments
    ##
    my $http_request   = OpenFrame::Segment::HTTP::Request->new();
    my $image_loader = OpenFrame::AppKit::Segment::Images->new()
                                                         ->directory("./templates");
    my $session_loader = OpenFrame::AppKit::Segment::SessionLoader->new();
    my $name_form      = OpenFrame::AppKit::Examples::NameForm->new()
                                                              ->uri( qr:/(index\.html|)$: )
							                                                ->namespace( 'nameform' );
    my $hangman        = OpenFrame::AppKit::Examples::Hangman->new()
	                                                     ->uri( '/hangman' )
                                    							     ->namespace( 'hangman' )
                                    							     ->wordlist( './words.txt' );
    my $content_loader = OpenFrame::AppKit::Segment::TT2->new()
                                                        ->directory("./templates");
    my $logger         = OpenFrame::AppKit::Segment::LogFile->new();


    ## order is important here.
    $pipeline->add_segment(
			   $http_request,
			   $image_loader,
			   $session_loader,
			   $name_form,
			   $hangman,
			   $content_loader,
			  );

    $pipeline->cleanups->add_segment( $logger );

    ## create a new store
    my $store = Pipeline::Store::Simple->new();

    ## add the request into the store and then add the store to the pipeline
    $pipeline->store( $store->set( $r ) );

    ## dispatch the pipeline
    $pipeline->dispatch();

    ## get the response out
    my $response = $pipeline->store->get('HTTP::Response');

    ## send it to the client.
    $c->send_response( $response );
  }
}



