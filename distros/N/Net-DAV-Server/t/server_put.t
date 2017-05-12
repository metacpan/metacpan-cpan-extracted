#!/usr/bin/perl

use Test::More;
eval "use IO::Scalar";
plan $@ ? (skip_all => 'IO::Scalar not available') : (tests => 20);
use Carp;

use strict;
use warnings;

use Net::DAV::Server ();
use Net::DAV::LockManager::Simple ();
use XML::LibXML;
use XML::LibXML::XPathContext;

my $parser = XML::LibXML->new();

use FindBin;
use lib "$FindBin::Bin/lib";
use Mock::Filesys;

{
    my $label = 'Simple file create';
    my $path = '/fred.txt';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( !$fs->test( 'e', $path ), "$label: target does not initially exist" );
    my $req = put_request( $path );

    my $resp = $dav->put( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 201, "$label: Response is 'Created'" );
    ok( $fs->test( 'f', $path ), "$label: target now exists" );
}

{
    my $label = 'Overwrite existing file';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'f', $path ), "$label: target does initially exist" );
    my $req = put_request( $path );

    my $resp = $dav->put( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 201, "$label: Response is 'Created'" );
    ok( $fs->test( 'f', $path ), "$label: target now exists" );
}

{
    my $label = 'Try to put a collection';
    my $path = '/foo';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'd', $path ), "$label: target is a collection" );
    my $req = put_request( $path );

    my $resp = $dav->put( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 405, "$label: Response is 'Method not allowed'" );
}

{
    my $label = 'Write file to non-existent directory';
    my $path = '/baz/foo/test.txt';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( !$fs->test( 'e', $path ), "$label: target does not exist" );
    my $req = put_request( $path );

    my $resp = $dav->put( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 409, "$label: Response is 'Conflict'" );
}

{
    my $label = 'Cannot write file';
    my $path = '/no_open';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( !$fs->test( 'e', $path ), "$label: target does not exist" );
    my $req = put_request( $path );

    my $resp = $dav->put( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 403, "$label: Response is 'Forbidden'" );
}

{
    my $label = 'Locked file, other';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    {
        my $req = lock_request( $path, { 'user' => 'bianca', 'owner_href' => 'Bianca' } );
        $dav->run( $req, HTTP::Response->new( 200 ) );
    }
    ok( $fs->test( 'e', $path ), "$label: target does exist" );
    my $req = put_request( $path );

    my $resp = $dav->put( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 403, "$label: Response is 'Forbidden'" );
}

{
    my $label = 'Locked directory, other';
    my $path = '/foo/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    {
        my $req = lock_request( '/foo', { 'user' => 'bianca', 'owner_href' => 'Bianca' } );
        $dav->run( $req, HTTP::Response->new( 200 ) );
    }
    ok( !$fs->test( 'e', $path ), "$label: target does not exist" );
    my $req = put_request( $path );

    my $resp = $dav->put( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 403, "$label: Response is 'Forbidden'" );
}

{
    my $label = 'Locked file, me';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;
    my $token;

    {
        my $req = lock_request( $path, { 'user' => 'fred', 'owner_href' => 'Fred' } );
        my $resp = $dav->run( $req, HTTP::Response->new( 200 ) );
        $token = $resp->header( 'Lock-Token' );
        $token =~ tr/<>//d;
    }
    ok( $fs->test( 'e', $path ), "$label: target does exist" );
    my $req = put_request( $path );
    $req->header( 'If', "<$token>" );
    my $resp = $dav->put( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 403, "$label: Response is 'Forbidden'" );
}

{
    my $label = 'Locked directory, me';
    my $path = '/foo/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;
    my $token;

    {
        my $req = lock_request( '/foo', { 'user' => 'fred', 'owner_href' => 'Fred' } );
        my $resp = $dav->lock( $req, HTTP::Response->new( 200 ) );
        $token = $resp->header( 'Lock-Token' );
        $token =~ tr/<>//d;
    }
    ok( !$fs->test( 'e', $path ), "$label: target does not exist" );
    my $req = put_request( $path );
    $req->header( 'If', "<$token>" );

    my $resp = $dav->put( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 403, "$label: Response is 'Forbidden'" );
}

# -------- Utility subs ----------

sub put_request {
    my ($path) = @_;

    my $req = HTTP::Request->new( put => $path );
    my $content = 'A little fake content.';
    $req->content( $content );
    $req->header( 'Content-Length', length $content );
    $req->authorization_basic( 'fred', 'fredmobile' );
    return $req;
}

sub lock_request {
    my ($uri, $args) = @_;
    my $req = HTTP::Request->new( 'LOCK' => $uri, (exists $args->{timeout}?[ 'Timeout' => $args->{timeout} ]:()) );
    $req->authorization_basic( $args->{'user'}||'fred', 'fredmobile' );
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
