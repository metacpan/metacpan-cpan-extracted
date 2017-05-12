#!/usr/bin/perl
# $Id: 60_static.t 1566 2010-11-03 03:13:32Z fil $

use strict;
use warnings;

use Data::Dumper;
use POE::Component::XUL;
use HTTP::Status;
use JSON::XS;

use t::PreReq;

use constant DEBUG=>0;

use Test::More ( tests=> 19 );
t::PreReq::load( 19, qw( HTTP::Request LWP::UserAgent ) );
use t::Client;
use t::Server;

BEGIN { unlink "poe-xul/xul/something.js.cache" }
END   { unlink "poe-xul/xul/something.js.cache" }

################################################################
my $Q = 5;
$Q *= 3 if $ENV{AUTOMATED_TESTING};

if( $ENV{HARNESS_PERL_SWITCHES} ) {
    $Q *= 3;
}

my $browser = t::Client->new();
my $pid = t::Server->spawn( $browser->{PORT}, 'poe-xul' );
END { kill 2, $pid if $pid; }

diag( "sleep $Q" ) unless $ENV{AUTOMATED_TESTING};
sleep $Q;

my $UA = LWP::UserAgent->new;

$UA->timeout( 2*60 );

############################################################
my $URI = $browser->root_uri;
my $resp = $UA->get( $URI );

ok( $resp->is_success, "Got the root" )
        or die Dumper $resp;
is( $resp->content_type, 'text/html', " ... and it's html" );
ok( ($resp->content !~ /404/), " ... and it looks OK" );
ok( $resp->header( 'Last-Modified' ), " ... and it was modified" );
ok( $resp->content_length, " ... seems big enough" );

############################################################
my $req = HTTP::Request->new( GET => $URI );

$req->header( 'If-Modified-Since' => $resp->header( 'Last-Modified' ) );

$resp = $UA->request( $req );

is( $resp->code, RC_NOT_MODIFIED, "Got the root again" )
        or die Dumper $resp;
is( $resp->content_type, 'text/html', " ... and it's html" );
ok( !$resp->header( 'Last-Modified' ), " ... and it was modified" );
is( $resp->content, '', " ... but it wasn't resent" );

############################################################
$req = HTTP::Request->new( HEAD => $URI );
# RFC1945 says HEAD should ingore if-modified-since
$req->header( 'If-Modified-Since' => $resp->header( 'Last-Modified' ) );

$resp = $UA->request( $req );

ok( $resp->is_success, "Got the root's HEAD" )
        or die Dumper $resp;
is( $resp->content_type, 'text/html', " ... and it's html" );
is( $resp->content, '', " ... but it wasn't resent" );
SKIP:
{
    skip "POE::Component::Server::HTTP clears content_type during HEAD", 1;
    ok( $resp->content_length, " ... but we got it's size" );
}
ok( $resp->header( 'Last-Modified' ), " ... and it was modified" );



############################################################
$URI = URI->new( $URI );
$URI->path( "/something.js" );
$req = HTTP::Request->new( GET => $URI );

$resp = $UA->request( $req );

ok( $resp->is_success, "Got the built-up JS" )
        or die Dumper $resp;
is( $resp->content_type, 'application/javascript', " ... and it's javascript" );
ok( $resp->header( 'Last-Modified' ), " ... and it was modified" );
my $t = $resp->content;
ok( ($t =~ /Ajax/ and $t =~ /Application/), " ... and it includes 'everything'" )
        or die "content=$t";
ok( $resp->content_length, " ... but we got it's size" );
