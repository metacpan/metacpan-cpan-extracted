#!/usr/bin/perl

use Test::More;
eval "use IO::Scalar";
plan $@ ? (skip_all => 'IO::Scalar not available') : (tests => 66);
use Carp;

use strict;
use warnings;

use HTTP::Request;
use HTTP::Response;
use XML::LibXML;

use Net::DAV::Server ();
use Net::DAV::LockManager::Simple ();

use FindBin;
use lib "$FindBin::Bin/lib";
use Mock::Filesys;

{
    my $label = 'Simple Exclusive Lock';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    $dav->filesys( Mock::Filesys->new() );
    my $resource = '/directory/file';

    my $req = lock_request( $resource,
        { timeout=>'Infinite, Second-4100000000', scope=>'exclusive', owner_href=>'http://example.org/~gwj/contact.html'}
    );
    my $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: Lock returns response" );
    is( $resp->code, 200, "\t... with a 'Success' status." );
    is_lock_response( $resp,
        { path=>$resource, owner_href=> 'http://example.org/~gwj/contact.html', depth=> 'infinity', scope=>'exclusive'},
        $label
    );
    my $token = $resp->header( 'Lock-Token' );
    $token =~ tr/<>//d;

    $req = unlock_request( $resource, $token );
    $resp = eval { $dav->unlock( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: unlock returns a response" );
    is( $resp->code, 204, "\t... with a 'No Content' status" );
}

{
    my $label = 'Simple Lock - bad unlock';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    $dav->filesys( Mock::Filesys->new() );
    my $resource = '/directory/file';

    my $req = lock_request( $resource,
        { timeout=>'Infinite, Second-4100000000', scope=>'exclusive', owner_href=>'http://example.org/~gwj/contact.html'}
    );
    my $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: Lock returns response" );
    is( $resp->code, 200, "\t... with a 'Success' status." );
    is_lock_response( $resp,
        { path=>$resource, owner_href=> 'http://example.org/~gwj/contact.html', depth=> 'infinity', scope=>'exclusive'},
        $label
    );
    my $token = $resp->header( 'Lock-Token' );
    $token =~ tr/<>//d;
    {
        my $label = 'Simple Lock - missing token';
        $req = unlock_request( $resource );
        $resp = eval { $dav->unlock( $req, HTTP::Response->new( 200 ) ); };
    print STDERR $@ if $@;
        isa_ok( $resp, 'HTTP::Response', "$label: unlock returns a response" );
        is( $resp->code, 400, "\t... with a 'Bad Request' status" );
    }

    {
        my $label = 'Simple Lock - bad token';
        my $bad = substr( $token, 0, (length $token) - 1 ) . 'B';
        $req = unlock_request( $resource, $bad );
        $resp = eval { $dav->unlock( $req, HTTP::Response->new( 200 ) ); };
    print STDERR $@ if $@;
        isa_ok( $resp, 'HTTP::Response', "$label: unlock returns a response" );
        is( $resp->code, 403, "\t... with a 'Forbidden' status" );
    }

    $req = unlock_request( $resource, $token );
    $resp = eval { $dav->unlock( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: unlock returns a response" );
    is( $resp->code, 204, "\t... with a 'No Content' status" );

    $req = unlock_request( $resource, $token );
    $resp = eval { $dav->unlock( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: unlock returns a response" );
    is( $resp->code, 409, "\t... with a 'Conflict' status" );
}

{
    my $label = 'Double Lock';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    $dav->filesys( Mock::Filesys->new() );
    my $resource = '/directory/file';

    my $req = lock_request( $resource,
        { timeout=>'Infinite, Second-4100000000', scope=>'exclusive', owner_href=>'http://example.org/~gwj/contact.html'}
    );
    my $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: First lock returns response" );
    is( $resp->code, 200, "\t... with a 'Success' status." );
    my $token = $resp->header( 'Lock-Token' );
    $req->header( 'If', '('.$token.')' );
    $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
    isa_ok( $resp, 'HTTP::Response', "$label: second lock return response" );
    is( $resp->code, 412, "\t... with a 'Precondition failed' error status." );

    $token =~ tr/<>//d;
    $req = unlock_request( $resource, $token );
    $resp = eval { $dav->unlock( $req, HTTP::Response->new( 200 ) ); };
    isa_ok( $resp, 'HTTP::Response', "$label: unlock returns a response" );
    is( $resp->code, 204, "\t... with a 'No Content' status" );
}

{
    my $label = 'Double Lock w/o token';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    $dav->filesys( Mock::Filesys->new() );
    my $resource = '/directory/file';

    my $req = lock_request( $resource,
        { timeout=>'Infinite, Second-4100000000', scope=>'exclusive', owner_href=>'http://example.org/~gwj/contact.html'}
    );
    my $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: First lock returns response" );
    is( $resp->code, 200, "\t... with a 'Success' status." );
    my $token = $resp->header( 'Lock-Token' );
    $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
    isa_ok( $resp, 'HTTP::Response', "$label: second lock return response" );
    is( $resp->code, 412, "\t... with a 'Precondition failed' error status." );

    $token =~ tr/<>//d;
    $req = unlock_request( $resource, $token );
    $resp = eval { $dav->unlock( $req, HTTP::Response->new( 200 ) ); };
    isa_ok( $resp, 'HTTP::Response', "$label: unlock returns a response" );
    is( $resp->code, 204, "\t... with a 'No Content' status" );
}

{
    my $label = 'Double Lock w/ bad token';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    $dav->filesys( Mock::Filesys->new() );
    my $resource = '/directory/file';

    my $req = lock_request( $resource,
        { timeout=>'Infinite, Second-4100000000', scope=>'exclusive', owner_href=>'http://example.org/~gwj/contact.html'}
    );
    my $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: First lock returns response" );
    is( $resp->code, 200, "\t... with a 'Success' status." );
    my $token = $resp->header( 'Lock-Token' );
    my $bad = substr( $token, 0, (length $token) - 2 ) . 'B>';
    $req->header( 'If', '('.$bad.')' );
    $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
    isa_ok( $resp, 'HTTP::Response', "$label: second lock return response" );
    is( $resp->code, 412, "\t... with a 'Precondition failed' error status." );

    $token =~ tr/<>//d;
    $req = unlock_request( $resource, $token );
    $resp = eval { $dav->unlock( $req, HTTP::Response->new( 200 ) ); };
    isa_ok( $resp, 'HTTP::Response', "$label: unlock returns a response" );
    is( $resp->code, 204, "\t... with a 'No Content' status" );
}

{
    my $label = 'Exclusive Lock no T/O';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    $dav->filesys( Mock::Filesys->new() );
    my $resource = '/directory/file';

    my $req = lock_request( $resource,
        { scope=>'exclusive', owner_href=>'http://example.org/~gwj/contact.html'}
    );
    my $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: Lock returns response" );
    is( $resp->code, 200, "\t... with a 'Success' status." );
    is_lock_response( $resp,
        { path=>$resource, owner_href=> 'http://example.org/~gwj/contact.html', depth=> 'infinity', scope=>'exclusive'},
        $label
    );
    my $token = $resp->header( 'Lock-Token' );
    $token =~ tr/<>//d;
    $req = unlock_request( $resource, $token );
    $resp = eval { $dav->unlock( $req, HTTP::Response->new( 200 ) ); };
    isa_ok( $resp, 'HTTP::Response', "$label: unlock returns a response" );
    is( $resp->code, 204, "\t... with a 'No Content' status" );
}

{
    my $label = 'Refresh Lock';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    $dav->filesys( Mock::Filesys->new() );
    my $resource = '/directory/file';

    my $req = lock_request( $resource,
        { timeout=>'Infinite, Second-4100000000', scope=>'exclusive', owner_href=>'http://example.org/~gwj/contact.html'}
    );
    my $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: First lock returns response" );
    is( $resp->code, 200, "\t... with a 'Success' status." );
    my $token = $resp->header( 'Lock-Token' );

    $token =~ tr/<>//d;
    $req = HTTP::Request->new( LOCK => $resource, [ 'Timeout' => 60, 'If' => "(<$token>)" ] );
    $req->authorization_basic( 'fred', 'fredmobile' );
    $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: second lock return response" );
    is( $resp->code, 200, "\t... with a 'Success' status." );
    is_lock_response( $resp,
        { path=>$resource, depth=> 'infinity', scope=>'exclusive', timeout => 60, token => $token },
        $label
    );

    $token =~ tr/<>//d;
    $req = unlock_request( $resource, $token );
    $resp = eval { $dav->unlock( $req, HTTP::Response->new( 200 ) ); };
    isa_ok( $resp, 'HTTP::Response', "$label: unlock returns a response" );
    is( $resp->code, 204, "\t... with a 'No Content' status" );
}

{
    my $label = 'Refresh Lock w/o token';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    $dav->filesys( Mock::Filesys->new() );
    my $resource = '/directory/file';

    my $req = HTTP::Request->new( LOCK => $resource, [ 'Timeout' => 60 ] );
    $req->authorization_basic( 'fred', 'fredmobile' );
    my $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
    isa_ok( $resp, 'HTTP::Response', "$label: second lock return response" );
    is( $resp->code, 403, "\t... with a 'Forbidden' error status." );
}

{
    my $label = 'Refresh Lock on unlocked resource';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    $dav->filesys( Mock::Filesys->new() );
    my $resource = '/directory/file';

    my $req = HTTP::Request->new( LOCK => $resource, [ 'Timeout' => 60, 'If' => "(<opaquelocktoken:ThisIsNotTheRightToken>)" ] );
    $req->authorization_basic( 'fred', 'fredmobile' );
    my $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
    isa_ok( $resp, 'HTTP::Response', "$label: second lock return response" );
    is( $resp->code, 412, "\t... with a 'Precondition Failed' error status." );
}

{
    my $label = 'Refresh Lock w/ wrong token';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    $dav->filesys( Mock::Filesys->new() );
    my $resource = '/directory/file';

    my $req = lock_request( $resource,
        { timeout=>'Infinite, Second-4100000000', scope=>'exclusive', owner_href=>'http://example.org/~gwj/contact.html'}
    );
    my $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: First lock returns response" );
    is( $resp->code, 200, "\t... with a 'Success' status." );
    my $token = $resp->header( 'Lock-Token' );

    $req = HTTP::Request->new( LOCK => $resource, [ 'Timeout' => 60, 'If' => "(<opaquelocktoken:ThisIsNotTheRightToken>)" ] );
    $req->authorization_basic( 'fred', 'fredmobile' );
    $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
    isa_ok( $resp, 'HTTP::Response', "$label: second lock return response" );
    is( $resp->code, 412, "\t... with a 'Precondition Failed' error status." );

    $token =~ tr/<>//d;
    $req = unlock_request( $resource, $token );
    $resp = eval { $dav->unlock( $req, HTTP::Response->new( 200 ) ); };
    isa_ok( $resp, 'HTTP::Response', "$label: unlock returns a response" );
    is( $resp->code, 204, "\t... with a 'No Content' status" );
}

{
    my $label = 'Refresh Lock w/ wrong user';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    $dav->filesys( Mock::Filesys->new() );
    my $resource = '/directory/file';

    my $req = lock_request( $resource,
        { timeout=>'Infinite, Second-4100000000', scope=>'exclusive', owner_href=>'http://example.org/~fred/contact.html'}
    );
    my $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: First lock returns response" );
    is( $resp->code, 200, "\t... with a 'Success' status." );
    my $token = $resp->header( 'Lock-Token' );

    $token =~ tr/<>//d;
    $req = HTTP::Request->new( LOCK => $resource, [ 'Timeout' => 60, 'If' => "(<$token>)" ] );
    $req->authorization_basic( 'wade', 'fredmobile' );
    $resp = eval { $dav->lock( $req, HTTP::Response->new( 200 ) ); };
    isa_ok( $resp, 'HTTP::Response', "$label: second lock return response" );
    is( $resp->code, 403, "\t... with a 'Forbidden' error status." );

    $token =~ tr/<>//d;
    $req = unlock_request( $resource, $token );
    $resp = eval { $dav->unlock( $req, HTTP::Response->new( 200 ) ); };
    isa_ok( $resp, 'HTTP::Response', "$label: unlock returns a response" );
    is( $resp->code, 204, "\t... with a 'No Content' status" );
}

{
    my $label = 'Bad path';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    $dav->filesys( Mock::Filesys->new() );
    my $resource = '/directory/../file';

    my $req = lock_request( $resource,
        { timeout=>'Infinite, Second-4100000000', scope=>'exclusive', owner_href=>'http://example.org/~gwj/contact.html'}
    );
    my $resp = eval { $dav->run( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: Lock returns response" );
    is( $resp->code, 400, "\t... with a 'Bad Request' status." );
}

{
    my $label = 'Bad depth';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    $dav->filesys( Mock::Filesys->new() );
    my $resource = '/directory/file';

    my $req = lock_request( $resource,
        { timeout=>'Infinite, Second-4100000000', depth => 3, scope=>'exclusive', owner_href=>'http://example.org/~gwj/contact.html'}
    );
    my $resp = eval { $dav->run( $req, HTTP::Response->new( 200 ) ); };
print STDERR $@ if $@;
    isa_ok( $resp, 'HTTP::Response', "$label: Lock returns response" );
    is( $resp->code, 400, "\t... with a 'Bad Request' status." );
}

sub lock_request {
    my ($uri, $args) = @_;
    my $req = HTTP::Request->new( 'LOCK' => $uri,
        [ (exists $args->{timeout}? ('Timeout' => $args->{timeout}) :()),
        (exists $args->{depth}? ('Depth' => $args->{depth}) :()) ]
    );
    $req->authorization_basic( 'fred', 'fredmobile' );
    if ( $args ) {
        my $scope = $args->{scope} || 'exclusive';
        $req->content( <<"BODY" );
<?xml version="1.0" encoding="utf-8"?>
<D:lockinfo xmlns:D='DAV:'>
    <D:lockscope><D:$scope /></D:lockscope>
    <D:locktype><D:write/></D:locktype>
    <D:owner>
        <D:href>$args->{owner_href}</D:href>
    </D:owner>
</D:lockinfo>
BODY
    }

    return $req;
}

sub is_lock_response {
    my ($resp, $args, $label) = @_;
    my @errors;
    my $token = $resp->header( 'Lock-Token' );
    if ( exists $args->{'token'} ) {
        push @errors, "Lock token '$token' found, but not expected" if $token;
        $token = $args->{'token'};
    }
    else {
        push @errors, 'Lock token not found' unless defined $token && $token =~ /^<[^>]+>$/;
    }
    my $p = XML::LibXML->new();
    my $doc = $resp->content ne '' ? $p->parse_string( $resp->content ) : undef;
    ASSERT: {
        do { push @errors, 'XML content not returned.'; last ASSERT; } unless defined $doc;
        my $root = $doc->documentElement();
        my $tag = $root->localname;
        do { push @errors, "Root element '$tag' received, 'prop' expected"; last ASSERT; }
            unless $tag eq 'prop';
        my $prefix = $root->prefix();
        my $ns = $root->lookupNamespaceURI($prefix);
        do { push @errors, "Root namespace '$ns' received, 'DAV:' expected."; last ASSERT; }
            unless $ns eq 'DAV:';
        my ($lock) = $root->findnodes( "$prefix:lockdiscovery/$prefix:activelock" );
        do { push @errors, 'activelock element not found'; last ASSERT; }
            unless defined $lock;
        push @errors, 'locktype is write'
            unless has_node( $lock, "$prefix:locktype/$prefix:write" );
        push @errors, "lockscope is not '$args->{'scope'}'"
            unless has_node( $lock, "$prefix:lockscope/$prefix:$args->{'scope'}" );
        my $depth = get_node_value( $lock, "$prefix:depth" );
        push @errors, "depth '$depth' received, '$args->{'depth'}' expected"
            unless $depth eq $args->{'depth'};
        my $timeout = get_node_value( $lock, "$prefix:timeout" );
        unless ( $timeout =~ s/^Second-(\d+)$/$1/ ) {
            push @errors, "Invalid timeout value '$timeout' received";
        }
        elsif ( $args->{'timeout'} ) {
            push @errors, "timeout '$timeout' received, '$args->{'timeout'}' expected"
                unless $timeout == $args->{'timeout'};
        }
        elsif ( $timeout > 15 * 60 ) {
            push @errors, "timeout value '$timeout' not within expected range.";
        }
        $token =~ tr/<>//d;
        my $ctoken = get_node_value( $lock, "$prefix:locktoken/$prefix:href" );
        push @errors, "Content lock token '$ctoken' received, '$token' expected"
            unless $ctoken eq $token;
        my $path = get_node_value( $lock, "$prefix:lockroot/$prefix:href" );
        push @errors, "Content lock root '$path' received, '$args->{'path'}' expected"
            unless $path eq $args->{'path'};
        my $owner = get_node_value( $lock, "$prefix:owner/$prefix:href" );
        push @errors, "Content owner href '$owner' received, '$args->{'owner_href'}' expected"
            if exists $args->{'owner_href'} && $owner ne $args->{'owner_href'};
    }
    if ( @errors ) {
        fail( "$label: valid lock response" );
        diag( map { "\t... $_\n" } @errors );
    }
    else {
        pass( "$label: valid lock response" );
    }
}

sub unlock_request {
    my ($uri, $token) = @_;
    my $req = HTTP::Request->new( 'UNLOCK' => $uri, ($token?[ 'Lock-Token' => "<$token>" ]:()) );
    $req->authorization_basic( 'fred', 'fredmobile' );
    return $req;
}

sub has_node {
    my ($node, $xpath) = @_;
    my @nodes = $node->findnodes( $xpath );
    return @nodes > 0;
}

sub get_node_value {
    my ($node, $xpath) = @_;
    my @nodes = $node->findnodes( $xpath );
    return '' unless @nodes;
    return $nodes[0]->textContent();
}

sub is_node_value {
    my ($node, $xpath, $expected, $label) = @_;
    my @nodes = $node->findnodes( $xpath );
    fail( "$label - missing node" ) unless @nodes;
    is( $nodes[0]->textContent(), $expected, $label );
}

sub like_node_value {
    my ($node, $xpath, $regex, $label) = @_;
    my @nodes = $node->findnodes( $xpath );
    fail( "$label - missing node" ) unless @nodes;
    like( $nodes[0]->textContent(), $regex, $label );
}
