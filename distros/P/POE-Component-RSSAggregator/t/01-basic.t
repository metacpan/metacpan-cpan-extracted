#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

use_ok('POE');
POE::Kernel->run();

__DATA__
use Test::More tests => 5;
use POE;
use POE::Component::RSSAggregator;
use HTTP::Status;
use POE::Component::Server::HTTP;

our %URLS = (
    test1 => \&test1,
    test2 => \&test2,
);

our @test1_xml = (
    q|<?xml version="1.0"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns="http://my.netscape.com/rdf/simple/0.9/"><channel><title>jbisbee.com</title>
    <link>http://www.jbisbee.com/</link><description>Testing PoCo::RSSAggregator</description>
    </channel><item><title>Friday 12th of November 2004 02:20:00 PM</title>
    <link>http://www.jbisbee.com/xml-rss-feed/test/1100294400</link></item></rdf:RDF>|,

    qq|<?xml version="1.0"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns="http://my.netscape.com/rdf/simple/0.9/"><channel><title>jbisbee.com</title>
    <link>http://www.jbisbee.com/</link><description>Testing PoCo::RSSAggregator</description>
    </channel><item><title>Friday 12th of November 2004 02:20:30 PM</title>
    <link>http://www.jbisbee.com/xml-rss-feed/test/1100294430</link></item></rdf:RDF>|
);

our @test2_xml = (
    q|<?xml version="1.0"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns="http://my.netscape.com/rdf/simple/0.9/"><channel><title>jbisbee.com</title>
    <link>http://poe.perl.org/</link><description>Testing PoCo::RSSAggregator</description>
    </channel><item><title>Friday 12th of November 2004 02:20:00 PM</title>
    <link>http://poe.perl.org/xml-rss-feed/test/1100294400</link></item></rdf:RDF>|,

    qq|<?xml version="1.0"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns="http://my.netscape.com/rdf/simple/0.9/"><channel><title>jbisbee.com</title>
    <link>http://poe.perl.org/</link><description>Testing PoCo::RSSAggregator</description>
    </channel><item><title>Friday 12th of November 2004 02:20:30 PM</title>
    <link>http://poe.perl.org/xml-rss-feed/test/1100294430</link></item></rdf:RDF>|
);

POE::Session->new(
    _start      => \&start,
    _stop       => sub { },
    _child      => sub { },
    handle_feed => \&handle_feed,
    closeshop   => \&closeshop,
    verify      => \&verify,
);
POE::Kernel->run();

sub start {
    my ( $heap, $session, $kernel ) = @_[ HEAP, SESSION, KERNEL ];
    my $postback = $session->postback("handle_feed");
    $heap->{rssagg}
        = POE::Component::RSSAggregator->new( callback => $postback );
    isa_ok( $heap->{rssagg}, "POE::Component::RSSAggregator" );
    $heap->{httpd} = spawn_http_server(12345);
    $kernel->call( $heap->{rssagg}->{alias}, 'add_feed', $_ ) for (
        {   name  => 'test1',
            url   => 'http://localhost:12345/test1',
            delay => 1
        },
        {   name  => 'test2',
            url   => 'http://localhost:12345/test2',
            delay => 1
        },
    );
    my @feeds = $heap->{rssagg}->feed_list();
    is( @feeds, 2, "Verify two feeds loaded" );
}

my %done = ( test1 => 0, test2 => 0 );
my $done = 0;

sub handle_feed {
    my ( $kernel, $session, $heap, $feed )
        = ( @_[ KERNEL, SESSION, HEAP ], $_[ARG1]->[0] );
    return if $done;
    isa_ok( $feed, "XML::RSS::Feed" );
    my $headlines = $feed->num_headlines;
    if ( $feed->late_breaking_news ) {
        $done{ $feed->name }++;
        $done = 1;
        for my $test (qw(test1 test2)) {
            $done = $done{$test};
        }
        $kernel->post( $session, 'closeshop' ) unless $done;
    }
}

sub closeshop {
    my ( $kernel, $heap ) = ( @_[ KERNEL, HEAP ] );
    $kernel->post( $heap->{httpd}{httpd}, "shutdown" );
    $kernel->post( $heap->{rssagg}->{alias}, 'shutdown' );
    $kernel->yield('verify');
}

sub verify {
    my ( $kernel, $heap ) = ( @_[ KERNEL, HEAP ] );
    my @feeds = $heap->{rssagg}->feed_list();
    is( @feeds, 0, "All feeds have been removed" );
}

sub spawn_http_server {
    my ($port) = shift;
    return POE::Component::Server::HTTP->new(
        Port           => $port,
        ContentHandler => { '/' => \&http_handler },
        Headers        => { Server => 'My Server' },
    );
}

sub http_handler {
    my ( $request, $response ) = @_;
    my $path = $request->uri->path;
    $path =~ s/^\///;
    my $xml = &{ $URLS{$path} }();
    $response->code( HTTP::Status::RC_OK() );
    $response->content($xml);
    return HTTP::Status::RC_OK();
}

sub test1 {
    my $xml = shift @test1_xml;
    push @test1_xml, $xml;
    return $xml;
}

sub test2 {
    my $xml = shift @test2_xml;
    push @test2_xml, $xml;
    return $xml;
}
