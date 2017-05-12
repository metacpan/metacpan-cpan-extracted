#!/usr/bin/perl
use strict;
use warnings;
use POE;
use POE::Component::AtomAggregator;

my @feeds = (
#    {
#        url   => "http://xantus.vox.com/library/posts/atom.xml",
#        name  => "xantus",
#        delay => 600,
#    },
    {   url   => "http://www.vox.com/explore/posts/atom.xml",
        name  => "vox",
        delay => 10,
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
    $heap->{atomagg} = POE::Component::AtomAggregator->new(
        alias    => 'atomagg',
        debug    => 1,
        callback => $session->postback("handle_feed"),
        tmpdir   => '/tmp',        # optional caching 
    );
    $kernel->post( 'atomagg', 'add_feed', $_ ) for @feeds;
}

sub handle_feed {
    my ( $kernel, $feed ) = ( $_[KERNEL], $_[ARG1]->[0] );
    for my $entry ( $feed->late_breaking_news ) {
        print "entry: $entry\n";
        # do stuff with the XML::Atom::Headline object
        print $entry->title . "\n";
    }
}
