#!/usr/bin/perl

use Test::More tests => 3;
use Carp;

use strict;
use warnings;

use HTTP::Request;
use HTTP::Response;

use Net::DAV::Server ();
use Net::DAV::LockManager::Simple ();

use FindBin;
use lib "$FindBin::Bin/lib";
use Mock::Filesys;

{
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $req = HTTP::Request->new( POST => '/index.html' );
    $req->authorization_basic( 'fred', 'fredmobile' );

    my $resp = $dav->post( $req, HTTP::Response->new() );
    is( $resp->code, 501, 'POST method not implemented here.' );
}

{
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new(), -dbobj => Net::DAV::LockManager::Simple->new() );
    my $lresp = $dav->lock( lock_request( '/' ), HTTP::Response->new );
    ok( $lresp && $lresp->code == 200, 'Lock successful' );
    my $req = HTTP::Request->new( POST => '/index.html' );
    $req->authorization_basic( 'bianca', 'fredmobile' );

    my $resp = $dav->post( $req, HTTP::Response->new() );
    is( $resp->code, 403, 'POST blocked by lock.' );
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
