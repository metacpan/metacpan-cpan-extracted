#!/usr/bin/perl

use Test::More tests => 78;
use Carp;

use strict;
use warnings;

use Net::DAV::Server ();
use Net::DAV::LockManager::Simple ();
use XML::LibXML;
use XML::LibXML::XPathContext;
 
my $parser = XML::LibXML->new();

{
    package Mock::Filesys;
    sub new {
        return bless {
            '/' =>                 [ 0, 0, 040777, 2, 1, 1, 0,    0, (time)x3, 1024, 1 ],
            '/foo' =>              [ 0, 0, 040777, 2, 1, 1, 0,    0, (time)x3, 1024, 1 ],
            '/foo/bar' =>          [ 0, 0, 040777, 2, 1, 1, 0,    0, (time)x3, 1024, 1 ],
            '/foo/bar/baz.html' => [ 0, 0, 0666,   1, 1, 1, 0, 1024, (time)x3, 1024, 1 ],
            '/test.html' =>        [ 0, 0, 0666,   1, 1, 1, 0, 1024, (time)x3, 1024, 1 ],
            '/foo/index.html' =>   [ 0, 0, 0666,   1, 1, 1, 0, 2048, (time)x3, 1024, 2 ],
            '/bar' =>              [ 0, 0, 040777, 2, 1, 1, 0,    0, (time)x3, 1024, 1 ],
        };
    }
    sub test {
        my ($self, $op, $path) = @_;

        if ( $op eq 'e' ) {
            return exists $self->{$path};
        }
        elsif ( $op eq 'd' ) {
            return unless exists $self->{$path};
            return (($self->{$path}->[2]&040000) ? 1 : 0);
        }
        else {
            die "Operation $op not implemented.";
        }
    }
    sub stat {
        my ($self, $path) = @_;

        return unless exists $self->{$path};
        return @{$self->{$path}};
    }
}

# Directory
{
    my $label = 'Depth 1 dir, default';
    my $path = '/';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'e', $path ), "$label: root directory exists" );
    my $lresp = $dav->lock( lock_request( $path ), HTTP::Response->new( 200 ) );
    ok( $lresp && $lresp->code == 200, "$label: root directory locked." );

    my $req = propfind_request( $path );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:href', $path, "$label: Path is correct" );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]',
        [ qw/creationdate getcontentlength getcontenttype getlastmodified supportedlock lockdiscovery resourcetype/ ],
        "$label: Property nodes"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:exclusive',
        "$label: supported scopes"
    );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:lockdiscovery',
        [ qw/activelock/ ],
        "$label: locks"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:locktype/D:write',
        "$label: correct type"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:lockscope/D:exclusive',
        "$label: correct scope"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:depth',
        'infinity',
        "$label: correct timeout form"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:timeout',
        qr/Second-\d+/,
        "$label: correct timeout form"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:locktoken/D:href',
        qr/opaquelocktoken:[-\da-f]+/,
        "$label: correct token form"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:lockroot/D:href',
        $path,
        "$label: root is correct"
    );
}

{
    my $label = 'Depth 1 dir, allprop';
    my $path = '/';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'e', $path ), "$label: root directory exists" );
    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:allprop/></D:propfind>'
    );

    my $lresp = $dav->lock( lock_request( $path ), HTTP::Response->new( 200 ) );
    ok( $lresp && $lresp->code == 200, "$label: root directory locked." );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:href', $path, "$label: Path is correct" );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]',
        [ qw/creationdate getcontentlength getcontenttype getlastmodified supportedlock lockdiscovery resourcetype/ ],
        "$label: Property nodes"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:exclusive',
        "$label: supported scopes"
    );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:lockdiscovery',
        [ qw/activelock/ ],
        "$label: locks"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:locktype/D:write',
        "$label: correct type"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:lockscope/D:exclusive',
        "$label: correct scope"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:depth',
        'infinity',
        "$label: correct timeout form"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:timeout',
        qr/Second-\d+/,
        "$label: correct timeout form"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:locktoken/D:href',
        qr/opaquelocktoken:[-\da-f]+/,
        "$label: correct token form"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:lockroot/D:href',
        $path,
        "$label: root is correct"
    );
}

{
    my $label = 'Directory, lockdiscovery';
    my $path = '/';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:lockdiscovery/></D:prop></D:propfind>'
    );

    my $lresp = $dav->lock( lock_request( $path ), HTTP::Response->new( 200 ) );
    ok( $lresp && $lresp->code == 200, "$label: root directory locked." );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:lockdiscovery',
        "$label: Property exists"
    );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:lockdiscovery',
        [ qw/activelock/ ],
        "$label: locks"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:locktype/D:write',
        "$label: correct type"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:lockscope/D:exclusive',
        "$label: correct scope"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:depth',
        'infinity',
        "$label: correct timeout form"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:timeout',
        qr/Second-\d+/,
        "$label: correct timeout form"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:locktoken/D:href',
        qr/opaquelocktoken:[-\da-f]+/,
        "$label: correct token form"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:lockroot/D:href',
        $path,
        "$label: root is correct"
    );
}

# File
{
    my $label = 'File, default';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'e', $path ), "$label: file exists" );
    my $req = propfind_request( $path );

    my $lresp = $dav->lock( lock_request( $path ), HTTP::Response->new( 200 ) );
    ok( $lresp && $lresp->code == 200, "$label: root directory locked." );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:href', $path, "$label: Path is correct" );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]',
        [ qw/creationdate getcontentlength getcontenttype getlastmodified supportedlock lockdiscovery resourcetype/ ],
        "$label: Property nodes"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:exclusive',
        "$label: supported scopes"
    );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:lockdiscovery',
        [ qw/activelock/ ],
        "$label: locks"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:locktype/D:write',
        "$label: correct type"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:lockscope/D:exclusive',
        "$label: correct scope"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:depth',
        'infinity',
        "$label: correct timeout form"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:timeout',
        qr/Second-\d+/,
        "$label: correct timeout form"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:locktoken/D:href',
        qr/opaquelocktoken:[-\da-f]+/,
        "$label: correct token form"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:lockroot/D:href',
        $path,
        "$label: root is correct"
    );
}

{
    my $label = 'File, allprop';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'e', $path ), "$label: file exists" );
    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:allprop/></D:propfind>'
    );

    my $lresp = $dav->lock( lock_request( $path ), HTTP::Response->new( 200 ) );
    ok( $lresp && $lresp->code == 200, "$label: root directory locked." );

    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:href', $path, "$label: Path is correct" );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]',
        [ qw/creationdate getcontentlength getcontenttype getlastmodified supportedlock lockdiscovery resourcetype/ ],
        "$label: Property nodes"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:supportedlock/D:lockentry/D:lockscope/D:exclusive',
        "$label: supported scopes"
    );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:lockdiscovery',
        [ qw/activelock/ ],
        "$label: locks"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:locktype/D:write',
        "$label: correct type"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:lockscope/D:exclusive',
        "$label: correct scope"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:depth',
        'infinity',
        "$label: correct timeout form"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:timeout',
        qr/Second-\d+/,
        "$label: correct timeout form"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:locktoken/D:href',
        qr/opaquelocktoken:[-\da-f]+/,
        "$label: correct token form"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:lockroot/D:href',
        $path,
        "$label: root is correct"
    );
}

{
    my $label = 'File, lockdiscovery';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );

    my $lresp = $dav->lock( lock_request( $path ), HTTP::Response->new( 200 ) );
    ok( $lresp && $lresp->code == 200, "$label: root directory locked." );

    my $req = propfind_request(
        $path,
        '<D:propfind xmlns:D="DAV:"><D:prop><D:lockdiscovery/></D:prop></D:propfind>'
    );
    my $resp = $dav->propfind( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 207, "$label: Response is 'Multi-Status'" );
    my $xpc = get_xml_context( $resp->content );
    has_text( $xpc, '/D:multistatus/D:response/D:propstat/D:status', 'HTTP/1.1 200 OK', "$label: Status is correct" );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:lockdiscovery',
        "$label: Property exists"
    );
    has_nodes( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop[1]/D:lockdiscovery',
        [ qw/activelock/ ],
        "$label: locks"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:locktype/D:write',
        "$label: correct type"
    );
    has_node( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:lockscope/D:exclusive',
        "$label: correct scope"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:depth',
        'infinity',
        "$label: correct timeout form"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:timeout',
        qr/Second-\d+/,
        "$label: correct timeout form"
    );
    like_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:locktoken/D:href',
        qr/opaquelocktoken:[-\da-f]+/,
        "$label: correct token form"
    );
    has_text( $xpc,
        '/D:multistatus/D:response/D:propstat/D:prop/D:lockdiscovery/D:activelock/D:lockroot/D:href',
        $path,
        "$label: root is correct"
    );
}

# -------- Utility subs ----------

sub propfind_request {
    my ($path, $content) = @_;

    my $req = HTTP::Request->new( PROPFIND => $path );
    if ( defined $content ) {
        $req->content( $content );
        $req->header( 'Content-Length', length $content );
    }
    $req->authorization_basic( 'fred', 'fredmobile' );
    return $req;
}

sub get_xml_context {
    my ($content) = @_;
    my $doc = eval { $parser->parse_string( $content ) };
    die "Unable to parse content.\n" unless defined $doc;
    my $xpc = XML::LibXML::XPathContext->new( $doc );
    $xpc->registerNs( 'D', 'DAV:' );
    return $xpc;
}

sub has_text {
    my ($xpc, $xpath, $expect, $label) = @_;
    my @nodes = $xpc->findnodes( "$xpath/text()" );
    unless ( defined $nodes[0] ) {
        fail( "$label : Node not found." );
        return;
    }
    is( $nodes[0]->data, $expect, $label );
}

sub like_text {
    my ($xpc, $xpath, $expect, $label) = @_;
    my @nodes = $xpc->findnodes( "$xpath/text()" );
    unless ( defined $nodes[0] ) {
        fail( "$label : Node not found." );
        return;
    }
    like( $nodes[0]->data, $expect, $label );
}

sub has_texts {
    my ($xpc, $xpath, $expect, $label) = @_;
    my @nodes = map { $_->data } $xpc->findnodes( "$xpath/text()" );
    unless ( defined $nodes[0] ) {
        fail( "$label : Node not found." );
        return;
    }
    is_deeply( \@nodes, $expect, $label );
}

sub has_nodes {
    my ($xpc, $xpath, $tags, $label) = @_;
    my @nodes = map { $_->localname } $xpc->findnodes( "$xpath/D:*" );
    unless ( defined $nodes[0] ) {
        fail( "$label : Node not found." );
        return;
    }
    is_deeply( \@nodes, $tags, $label );
}

sub has_node {
    my ($xpc, $xpath, $label) = @_;
    my @nodes = $xpc->findnodes( $xpath );
    ok ( defined $nodes[0], $label );
}

sub lock_request {
    my ($uri, $args) = @_;
    my $req = HTTP::Request->new( 'LOCK' => $uri, (exists $args->{timeout}?[ 'Timeout' => $args->{timeout} ]:()) );
    $req->authorization_basic( 'fred', 'fredmobile' );
    if ( $args ) {
        my $scope = $args->{scope} || 'exclusive';
        $req->content( <<"BODY" );
<?xml version="1.0" encoding="utf-8"?>
<D:lockinfo xmlns:D='DAV:'>
    <D:lockscope><D:$scope /></D:lockscope>
    <D:locktype><D:write/></D:locktype>
    <D:owner>
        <D:href>http://fred.org/</D:href>
    </D:owner>
</D:lockinfo>
BODY
    }

    return $req;
}
