#!/usr/bin/perl
# $Id: 51_error.t 1566 2010-11-03 03:13:32Z fil $

use strict;
use warnings;

use POE::Component::XUL;
use JSON::XS;

use constant DEBUG=>0;

use t::PreReq;
use Test::More qw( no_plan );
t::PreReq::load( 1, qw( LWP::UserAgent ) );

use t::Client;
use t::Server;

my $Q = 5;

if( $ENV{HARNESS_PERL_SWITCHES} ) {
    $Q *= 3;
}

unless( $ENV{AUTOMATED_TESTING} ) {
    diag( "" );
    diag( "" );
    diag( "We are testing several error conditions.  Because of this you" );
    diag( "might see some error messages.  These may be ignored." );
    diag( "" );
}

my $browser = t::Client->new();
my $pid = t::Server->spawn( $browser->{PORT} );
END { kill 2, $pid if $pid; }

diag( "sleep $Q" ) unless $ENV{AUTOMATED_TESTING};
sleep $Q;

my $UA = LWP::UserAgent->new;

$UA->timeout( 2*60 );

############################################################
# Request for an unknown application
$browser = t::Client->new( APP=>'Bad' );

my $URI = $browser->boot_uri;
my $resp = $UA->get( $URI );

is( $resp->code, 404, "Not found" );
ok( ($resp->content =~ /inconnue : Bad/), "Can't find the application" )
        or warn $resp->content;

############################################################
# Request for an unknown SID;
$browser = t::Client->new( APP=>'Test', SID=>'honk-honk' );
$URI = $browser->Click_uri( { id=>'1234' } );
$resp = $UA->get( $URI );

is( $resp->code, 410, "Session is gone" );
my $C = $resp->content;
ok( ($C =~ /honk-honk/), "Can't find the session" )
        or warn $resp->content;

ok( ($C =~ m(a href="http://[-.\w]+:8881/start\.xul\?Test") ),
        "Link to start a new session" )
            or die $C;

############################################################
# Request, but a bad mime-type
$browser = t::Client->new( APP=>'Test' );
$URI = $browser->base_uri;
my $req = HTTP::Request->new( POST => $URI );
$req->content_type( 'text/html' );
$C = <<HTML;
<html><body><p>this is some HTML</p></body></html>
HTML
$req->content_length( length $C );
$req->content( $C );
$resp = $UA->request( $req );

is( $resp->code, 415, "Bad media type" );
ok( ($resp->content =~ /argument parsing/), "Doesn't like the content-type" )
        or warn $resp->content;

############################################################
# Request, but a bad method
$req->method( 'PUT' );
$resp = $UA->request( $req );

is( $resp->code, 405, "Bad method" );
ok( ($resp->content =~ /argument parsing/), "Doesn't like PUT" )
        or warn $resp->content;

############################################################
# Request, but a illegal JSON
$req->method( 'POST' );
$req->content_type( 'application/json' );
$C = "{ honk bonk zonk";
$req->content_length( length $C );
$req->content( $C );
$resp = $UA->request( $req );

is( $resp->code, 400, "Bad method" );
ok( ($resp->content =~ /argument parsing/), "Doesn't like bad JSON" )
        or warn $resp->content;

############################################################
# Request, but unknown source_ID
SKIP: {
    skip "Unit test not working", 1;
    $URI = $browser->boot_uri;
    $resp = $UA->get( $URI );

    my $data = $browser->decode_resp( $resp, 'boot' );
    $browser->handle_resp( $data, 'boot' );

    $URI = $browser->Click_uri( { id=>'1234' } );
    $resp = $UA->get( $URI );

    is( $resp->code, 500, "Internal error" );
    ok( ($resp->content =~ /source node 1234/), "Can't find the button" )
        or warn $resp->content;
}
# use Data::Dumper;
# die Dumper $resp;

############################################################



