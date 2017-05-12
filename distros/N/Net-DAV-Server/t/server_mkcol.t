#!/usr/bin/perl

use Test::More tests => 24;
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
    my $label = 'Simple MKCOL';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = Mock::Filesys->new();
    $dav->filesys( $fs );

    ok( !$fs->test( 'e', '/fred' ), "$label: target does not initially exist" );
    my $req = HTTP::Request->new( MKCOL => '/fred' );
    $req->authorization_basic( 'fred', 'fredmobile' );

    my $resp = $dav->mkcol( $req, HTTP::Response->new() );
    is( $resp->code, 201, "$label: Response is success" );
    ok( $fs->test( 'd', '/fred' ), "$label: target has now been created" );
}

{
    my $label = 'Content not supported';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = Mock::Filesys->new();
    $dav->filesys( $fs );

    ok( !$fs->test( 'e', '/fred' ), "$label: target does not initially exist" );
    my $req = HTTP::Request->new( MKCOL => '/fred' );
    $req->content( 'Content not allowed.' );
    $req->authorization_basic( 'fred', 'fredmobile' );

    my $resp = $dav->mkcol( $req, HTTP::Response->new() );
    is( $resp->code, 415, "$label: Response is success" );
    ok( !$fs->test( 'd', '/fred' ), "$label: target was not created" );
}

{
    my $label = 'Existing dir';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = Mock::Filesys->new();
    $dav->filesys( $fs );

    ok( $fs->test( 'e', '/foo' ), "$label: target does initially exist" );
    my $req = HTTP::Request->new( MKCOL => '/foo' );
    $req->authorization_basic( 'fred', 'fredmobile' );

    my $resp = $dav->mkcol( $req, HTTP::Response->new() );
    is( $resp->code, 405, "$label: Response is failure" );
    ok( $fs->test( 'd', '/foo' ), "$label: target still exists" );
}

{
    my $label = 'Create where file exists';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = Mock::Filesys->new();
    $dav->filesys( $fs );

    ok( $fs->test( 'e', '/test.html' ), "$label: target does initially exist" );
    my $req = HTTP::Request->new( MKCOL => '/test.html' );
    $req->authorization_basic( 'fred', 'fredmobile' );

    my $resp = $dav->mkcol( $req, HTTP::Response->new() );
    is( $resp->code, 405, "$label: Response is failure" );
    ok( $fs->test( 'f', '/test.html' ), "$label: target still exists" );
}


{
    my $label = 'Parent locked';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = Mock::Filesys->new();
    $dav->filesys( $fs );

    lock_resource( $dav, '/' );

    ok( !$fs->test( 'e', '/fred' ), "$label: target does not initially exist" );
    my $req = HTTP::Request->new( MKCOL => '/fred' );
    $req->authorization_basic( 'fred', 'fredmobile' );

    my $resp = $dav->mkcol( $req, HTTP::Response->new() );
    is( $resp->code, 403, "$label: Response is failure" );
    ok( !$fs->test( 'd', '/fred' ), "$label: target still exists" );
}

{
    my $label = 'Parent locked, token';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = Mock::Filesys->new();
    $dav->filesys( $fs );

    my $token = lock_resource( $dav, '/' );

    ok( !$fs->test( 'e', '/fred' ), "$label: target does not initially exist" );
    my $req = HTTP::Request->new( MKCOL => '/fred' );
    $req->authorization_basic( 'fred', 'fredmobile' );
    $req->header( 'If', "(<$token>)" );

    my $resp = $dav->mkcol( $req, HTTP::Response->new() );
    is( $resp->code, 201, "$label: Response is failure" );
    ok( $fs->test( 'd', '/fred' ), "$label: target created" );
}


{
    my $label = 'Ancestor locked';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = Mock::Filesys->new();
    $dav->filesys( $fs );

    lock_resource( $dav, '/' );

    ok( !$fs->test( 'e', '/foo/fred' ), "$label: target does not initially exist" );
    my $req = HTTP::Request->new( MKCOL => '/foo/fred' );
    $req->authorization_basic( 'fred', 'fredmobile' );

    my $resp = $dav->mkcol( $req, HTTP::Response->new() );
    is( $resp->code, 403, "$label: Response is failure" );
    ok( !$fs->test( 'd', '/foo/fred' ), "$label: target not created" );
}

{
    my $label = 'Ancestor locked, token';
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = Mock::Filesys->new();
    $dav->filesys( $fs );

    my $token = lock_resource( $dav, '/' );

    ok( !$fs->test( 'e', '/foo/fred' ), "$label: target does not initially exist" );
    my $req = HTTP::Request->new( MKCOL => '/foo/fred' );
    $req->authorization_basic( 'fred', 'fredmobile' );
    $req->header( 'If', "(<$token>)" );

    my $resp = $dav->mkcol( $req, HTTP::Response->new() );
    is( $resp->code, 201, "$label: Response is failure" );
    ok( $fs->test( 'd', '/foo/fred' ), "$label: target now exists" );
}


sub lock_resource {
    my ($dav, $path, $args) = (@_, {});

    my $req = HTTP::Request->new( 'LOCK' => $path, (exists $args->{timeout}?[ 'Timeout' => $args->{timeout} ]:()) );
    $req->authorization_basic( 'fred', 'fredmobile' );
    if ( $args ) {
        my $scope = $args->{scope} || 'exclusive';
        my $owner = 'Fred';
        $req->content( <<"BODY" );
<?xml version="1.0" encoding="utf-8"?>
<D:lockinfo xmlns:D='DAV:'>
    <D:lockscope><D:$scope /></D:lockscope>
    <D:locktype><D:write/></D:locktype>
    <D:owner>$owner</D:owner>
</D:lockinfo>
BODY
    }

    my $resp = $dav->lock( $req, HTTP::Response->new() );
    my $token = $resp->header( 'Lock-Token' );
    $token =~ tr/<>//d;
    return $token;
}
