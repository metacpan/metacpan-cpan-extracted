#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

use_ok("POE");
POE::Kernel->run();

__DATA__

use Test::More tests => 5;
use POE;
use POE::Component::AtomAggregator;
use HTTP::Status;
use POE::Component::Server::HTTP;

our %URLS = (
    test1 => \&test1,
    test2 => \&test2,
);

our @test1_xml = (

    qq|<?xml version="1.0" encoding="utf-8"?>
<feed
    xmlns="http://www.w3.org/2005/Atom"
    xmlns:at="http://www.sixapart.com/ns/at"
    xmlns:icbm="http://postneo.com/icbm"
    xmlns:rvw="http://purl.org/NET/RVW/0.2/"
    xml:lang="en">
    <title>Xantus</title>
    <link rel="self" type="application/atom+xml" title="Xantus (Atom)" href="http://xantus.vox.com/library/posts/page/1/atom.xml" />
    <link rel="alternate" type="text/html" title="Xantus" href="http://xantus.vox.com/library/posts/page/1/"/> 
    <link rel="service.post" type="application/atom+xml" title="Xantus" href="http://www.vox.com/atom/svc=post/collection_id=6a00b8ea0728391bc000b8ea07283c1bc0" /> 
    <link rel="service.subscribe" type="application/atom+xml" title="Xantus" href="http://xantus.vox.com/library/posts/atom.xml" />    
    <link rel="next" type="application/atom+xml" title="Xantus" href="http://xantus.vox.com/library/posts/page/2/atom.xml" /> 
    <link rel="last" type="application/atom+xml" title="Xantus" href="http://xantus.vox.com/library/posts/page/6/atom.xml" />  
    <generator uri="http://www.vox.com/">Vox</generator>
    <updated>2006-11-27T21:52:49Z</updated> 
    <author>

        <name>David Davis</name>
        <uri>http://xantus.vox.com/</uri>
    </author> 
    <id>tag:vox.com,2006:6p00b8ea0728391bc0/</id> 
    <subtitle>Making mistaeks along the way</subtitle>  
    
    <entry>
        <title>Send a letter to a soldier this holiday</title>   
        <link rel="alternate" type="text/html" title="Send a letter to a soldier this holiday" href="http://xantus.vox.com/library/post/send-a-letter-to-a-soldier-this-holiday.html" />  
        <link rel="service.post" type="application/atom+xml" title="Send a letter to a soldier this holiday" href="http://xantus.vox.com/library/post/send-a-letter-to-a-soldier-this-holiday.html#comments" /> 
        <link rel="service.edit" type="application/atom+xml" title="Send a letter to a soldier this holiday" href="http://www.vox.com/atom/svc=post/asset_id=6a00b8ea0728391bc000cdf3a30259cb8f" />          <id>tag:vox.com,2006-11-27:asset-6a00b8ea0728391bc000cdf3a30259cb8f</id>

        <published>2006-11-27T21:52:49Z</published>
        <updated>2006-11-27T21:52:49Z</updated>
    
        <author>
            <name>David Davis</name>
            <uri>http://xantus.vox.com/</uri>
        </author>
    
        
        <content type="html" xml:base="http://xantus.vox.com/">

            <![CDATA[
                <div xmlns="http://www.w3.org/1999/xhtml" xmlns:at="http://www.sixapart.com/ns/at">
       <p><br />I was a US Army soldier a number of years ago, and one holiday during my service stands out.&#160; I was stationed in Waegwan, South Korea, and I was away from family for nearly a year by the time December rolled around.&#160; I received a letter from a little girl in the states.&#160; The letter was addressed to &#39;Any Soldier&#39; (see below).&#160; This letter definitely helped me during a depressing time away from family.</p><p>So, I&#39;m asking you, my fellow voxers, to take a minute of your time and send a letter or card to a soldier this holiday.</p><p>Here&#39;s how:</p><p>Find a soldier at <a href="http://anysoldier.com/">anysoldier.com</a>, and send them a letter.</p><p>Also, you can send cards and letters to a wounded soldier.</p><p>Wounded Soldier<br />Red Cross - Walter Reed Army Medical Center<br />6900 Georgia Avenue NW - Heaton Pavillion - 3EO5<br />Washington, DC 20307</p><p><br />Thank you, and Happy Holidays!</p><p>-Xantus<br /></p> 
                </div>
            ]]>
        </content> 
    <category term="christmas" scheme="http://xantus.vox.com/tags/christmas/" label="christmas" /> 
    <category term="holiday" scheme="http://xantus.vox.com/tags/holiday/" label="holiday" /> 
    <category term="red cross" scheme="http://xantus.vox.com/tags/red+cross/" label="red cross" /> 
    <category term="wounded soldier" scheme="http://xantus.vox.com/tags/wounded+soldier/" label="wounded soldier" /> 
    <category term="anysoldier" scheme="http://xantus.vox.com/tags/anysoldier/" label="anysoldier" /> 
    </entry></feed>|,

    qq|<?xml version="1.0" encoding="utf-8"?>
<feed
    xmlns="http://www.w3.org/2005/Atom"
    xmlns:at="http://www.sixapart.com/ns/at"
    xmlns:icbm="http://postneo.com/icbm"
    xmlns:rvw="http://purl.org/NET/RVW/0.2/"
    xml:lang="en">
    <title>Xantus</title>
    <link rel="self" type="application/atom+xml" title="Xantus (Atom)" href="http://xantus.vox.com/library/posts/page/1/atom.xml" />
    <link rel="alternate" type="text/html" title="Xantus" href="http://xantus.vox.com/library/posts/page/1/"/> 
    <link rel="service.post" type="application/atom+xml" title="Xantus" href="http://www.vox.com/atom/svc=post/collection_id=6a00b8ea0728391bc000b8ea07283c1bc0" /> 
    <link rel="service.subscribe" type="application/atom+xml" title="Xantus" href="http://xantus.vox.com/library/posts/atom.xml" />    
    <link rel="next" type="application/atom+xml" title="Xantus" href="http://xantus.vox.com/library/posts/page/2/atom.xml" /> 
    <link rel="last" type="application/atom+xml" title="Xantus" href="http://xantus.vox.com/library/posts/page/6/atom.xml" />  
    <generator uri="http://www.vox.com/">Vox</generator>
    <updated>2006-11-27T21:52:49Z</updated> 
    <author>

        <name>David Davis</name>
        <uri>http://xantus.vox.com/</uri>
    </author> 
    <id>tag:vox.com,2006:6p00b8ea0728391bc0/</id> 
    <subtitle>Making mistaeks along the way</subtitle>  
<entry>
        <title>Vox Hunt: City Love</title>   
        <link rel="alternate" type="text/html" title="Vox Hunt: City Love" href="http://xantus.vox.com/library/post/vox-hunt-city-love.html" />  
        <link rel="service.post" type="application/atom+xml" title="Vox Hunt: City Love" href="http://xantus.vox.com/library/post/vox-hunt-city-love.html#comments" /> 
        <link rel="service.edit" type="application/atom+xml" title="Vox Hunt: City Love" href="http://www.vox.com/atom/svc=post/asset_id=6a00b8ea0728391bc000cdf7e62748094f" />            <id>tag:vox.com,2006-11-20:asset-6a00b8ea0728391bc000cdf7e62748094f</id>
        <published>2006-11-20T22:18:12Z</published>

        <updated>2006-11-20T22:18:12Z</updated>
    
        <author>
            <name>David Davis</name>
            <uri>http://xantus.vox.com/</uri>
        </author>
    
        
        <content type="html" xml:base="http://xantus.vox.com/">
            <![CDATA[
                <div xmlns="http://www.w3.org/1999/xhtml" xmlns:at="http://www.sixapart.com/ns/at">
       <blockquote><p>Show us why you love the city you live in.<br /><span style="font-size: 0.8em;">Submitted by <a at:user-xid="6p00c2252303c3604a" class="enclosure-inline-user" href="http://msredshoes.vox.com/">meg</a>.</span><br /> </p></blockquote>



 


    
    

    
<div at:enclosure="asset" at:xid="6a00b8ea0728391bc000c225223d17f219" at:format="large" at:align="center"
    class="enclosure enclosure-center enclosure-large" 
     style="text-align: center;">
<div class="enclosure-inner enclosure-photo" style="padding: 10px; border: 1px solid; width: 320px; margin: 10px auto;">
    <div class="enclosure-list">
        <div class="enclosure-item photo-asset last">
            <div class="enclosure-image">
        
                <a href="http://xantus.vox.com/library/photo/6a00b8ea0728391bc000c225223d17f219.html"><img src="http://a7.vox.com/6a00b8ea0728391bc000c225223d17f219-320pi" alt="Sunset behind boat at pier 39" title="Sunset behind boat at pier 39" /></a>
        
            </div>
            <div class="enclosure-meta">
                <div class="enclosure-asset-name"><a href="http://xantus.vox.com/library/photo/6a00b8ea0728391bc000c225223d17f219.html" title="Sunset behind boat at pier 39">Sunset behind boat at pier 39</a></div>                <div class="enclosure-comments comments"><a href="http://xantus.vox.com/library/photo/6a00b8ea0728391bc000c225223d17f219.html#comments" title="Leave a comment">
                        2 comments
                    </a></div>
            </div>
        </div>
    </div>
</div>
</div><!-- end enclosure -->

 <div><br /><br />I took this picture at Pier 39 in San Francisco.<br /></div> 
                </div>
            ]]>

        </content> 
    <category term="san francisco" scheme="http://xantus.vox.com/tags/san+francisco/" label="san francisco" /> 
    <category term="pier" scheme="http://xantus.vox.com/tags/pier/" label="pier" /> 
    <category term="pier 39" scheme="http://xantus.vox.com/tags/pier+39/" label="pier 39" /> 
    <category term="vox hunt" scheme="http://xantus.vox.com/tags/vox+hunt/" label="vox hunt" /> 
    <category term="city love" scheme="http://xantus.vox.com/tags/city+love/" label="city love" /> 
    </entry></feed>|
);

our @test2_xml = @text1_xml;

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
    $heap->{atomagg}
        = POE::Component::AtomAggregator->new( callback => $postback );
    isa_ok( $heap->{atomagg}, "POE::Component::AtomAggregator" );
    $heap->{httpd} = spawn_http_server(12345);
    $kernel->call( $heap->{atomagg}->{alias}, 'add_feed', $_ ) for (
        {   name  => 'test1',
            url   => 'http://localhost:12345/test1',
            delay => 1
        },
        {   name  => 'test2',
            url   => 'http://localhost:12345/test2',
            delay => 1
        },
    );
    my @feeds = $heap->{atomagg}->feed_list();
    is( @feeds, 2, "Verify two feeds loaded" );
}

my %done = ( test1 => 0, test2 => 0 );
my $done = 0;

sub handle_feed {
    my ( $kernel, $session, $heap, $feed )
        = ( @_[ KERNEL, SESSION, HEAP ], $_[ARG1]->[0] );
    return if $done;
    isa_ok( $feed, "XML::Atom::Feed" );
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
    $kernel->post( $heap->{atomagg}->{alias}, 'shutdown' );
    $kernel->yield('verify');
}

sub verify {
    my ( $kernel, $heap ) = ( @_[ KERNEL, HEAP ] );
    my @feeds = $heap->{atomagg}->feed_list();
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
