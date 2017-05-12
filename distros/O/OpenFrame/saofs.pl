#!/usr/bin/perl

##
## simple openframe server
##

use lib './lib';
use strict;
use warnings;

use Pipeline;
use HTTP::Daemon;
use Data::Dumper;
use OpenFrame::Segment::HTTP::Request;
use OpenFrame::Segment::ContentLoader;

my $d = HTTP::Daemon->new( LocalPort => '8080', Reuse => 1);
die $! unless $d;

print "server running at http://localhost:8080/\n";

## wait for connections
while(my $c = $d->accept()) {
  ## get requests of the connection
  while(my $r = $c->get_request) {

    ## create a new Pipeline object
    my $pipeline = Pipeline->new();

    ##
    ## create the segments
    ##

    ## the http request segment turns an HTTP request into something we
    ## can deal with...
    my $hr = OpenFrame::Segment::HTTP::Request->new();

    ## the content loader simply loads the file that we are 
    ## looking for based on the URI
    my $cl = OpenFrame::Segment::ContentLoader->new()
                                          ->directory("./webpages");

    ## add the two segments to the pipeline
    $pipeline->add_segment( $hr, $cl );

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



