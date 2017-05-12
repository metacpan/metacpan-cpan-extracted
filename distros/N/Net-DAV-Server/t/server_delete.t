#!/usr/bin/perl

use Test::More tests => 21;
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
use Mock::Filesys ();

{
    my $label = 'Non-existing file';
    my $path = '/fred.txt';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( !$fs->test( 'e', $path ), "$label: target does not initially exist" );
    my $req = delete_request( $path );

    my $resp = $dav->delete( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 404, "$label: Response is 'Not Found'" );
    ok( !$fs->test( 'f', $path ), "$label: target no long exists" );
}

{
    my $label = 'Fragment';
    my $path = '/fred.txt#top';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    my $req = delete_request( $path );

    my $resp = $dav->delete( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 404, "$label: Response is 'Not Found'" );
}

{
    my $label = 'Existing file';
    my $path = '/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'f', $path ), "$label: target does initially exist" );
    my $req = delete_request( $path );

    my $resp = $dav->delete( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 204, "$label: Response is 'No Content'" );
    ok( !$fs->test( 'f', $path ), "$label: target no longer exists" );
}

{
    my $label = 'Empty collection';
    my $path = '/goo';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    ok( $fs->test( 'd', $path ), "$label: target is a collection" );
    my $req = delete_request( $path );

    my $resp = $dav->delete( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 204, "$label: Response is 'No Content'" );
}

{
    my $label = 'Collection w/ depth';
    my $path = '/foo/bar';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;
    my @list = grep { substr( $_, 0, 4 ) eq $path } keys %{$fs->{'fs'}};

    ok( $fs->test( 'd', $path ), "$label: target is a collection" );
    is_deeply( [ grep { $fs->test( 'e', $_ ) } @list ], \@list, "$label: Initial set of files exists." );
    my $req = delete_request( $path );

    my $resp = $dav->delete( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 204, "$label: Response is 'No Content'" );
    is_deeply( [ grep { $fs->test( 'e', $_ ) } @list ], [], "$label: All files/directories removed." );
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
    my $req = delete_request( $path );

    my $resp = $dav->delete( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 403, "$label: Response is 'Forbidden'" );
}

{
    my $label = 'Locked directory, other';
    my $path = '/foo/bar/test.html';
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $fs = $dav->filesys;

    {
        my $req = lock_request( '/foo', { 'user' => 'bianca', 'owner_href' => 'Bianca' } );
        $dav->run( $req, HTTP::Response->new( 200 ) );
    }
    ok( !$fs->test( 'e', $path ), "$label: target does not exist" );
    my $req = delete_request( $path );

    my $resp = $dav->delete( $req, HTTP::Response->new( 200, 'OK' ) );
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
    my $req = delete_request( $path );
    $req->header( 'If', "<$token>" );
    my $resp = $dav->delete( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 403, "$label: Response is 'Forbidden'" );
}

{
    my $label = 'Locked directory, me';
    my $path = '/foo/bar/test.html';
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
    my $req = delete_request( $path );
    $req->header( 'If', "<$token>" );

    my $resp = $dav->delete( $req, HTTP::Response->new( 200, 'OK' ) );
    is( $resp->code, 403, "$label: Response is 'Forbidden'" );
}

# -------- Utility subs ----------

sub delete_request {
    my ($path) = @_;

    my $req = HTTP::Request->new( DELETE => $path );
    my $content = 'A little fake content.';
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
