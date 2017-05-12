#!/usr/bin/perl
use strict;
use warnings;
use POE;
use POE::Component::RSSAggregator;

my @feeds = (
    {   url   => "http://www.jbisbee.com/rdf/",
        name  => "jbisbee",
        delay => 10,
    },
    {   url   => "http://lwn.net/headlines/rss",
        name  => "lwn",
        delay => 300,
    },
);

POE::Session->create(
    inline_states => {
        _start      => \&init_session,
        handle_feed => \&handle_feed,
    },
);

$poe_kernel->run();

sub init_session {
    my ( $kernel, $heap, $session ) = @_[ KERNEL, HEAP, SESSION ];
    $heap->{rssagg} = POE::Component::RSSAggregator->new(
        alias    => 'rssagg',
        debug    => 1,
        callback => $session->postback("handle_feed"),
        tmpdir   => '/tmp',        # optional caching 
    );
    $kernel->post( 'rssagg', 'add_feed', $_ ) for @feeds;
}

sub handle_feed {
    my ( $kernel, $feed ) = ( $_[KERNEL], $_[ARG1]->[0] );
    for my $headline ( $feed->late_breaking_news ) {

        # do stuff with the XML::RSS::Headline object
        print $headline->headline . "\n";
    }
}
