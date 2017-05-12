#!/usr/bin/perl
# $Id: 50_poe.t 1023 2008-05-24 03:10:20Z fil $

use strict;
use warnings;

use POE::Component::XUL;
use JSON::XS;
use Data::Dumper;

use constant DEBUG=>0;

use t::PreReq;
use Test::More qw( no_plan );
t::PreReq::load( 1, qw( HTTP::Request LWP::UserAgent ) );

use t::Client;
use t::Server;


################################################################

my $Q = 5;
$Q *= 3 if $ENV{AUTOMATED_TESTING};

if( $ENV{HARNESS_PERL_SWITCHES} ) {
    $Q *= 3;
}

my $browser = t::Client->new();

my $pid = t::Server->spawn( $browser->{PORT} );
END { kill 2, $pid if $pid; }


diag( "sleep $Q" ) unless $ENV{AUTOMATED_TESTING};
sleep $Q;

my $UA = LWP::UserAgent->new;

$UA->timeout( 2*60 );

############################################################
my $URI = $browser->boot_uri;
my $resp = $UA->get( $URI );

my $data = $browser->decode_resp( $resp, 'boot' );
$browser->check_boot( $data );

$browser->handle_resp( $data, 'boot' );

ok( $browser->{W}, "Got a window" );
is( $browser->{W}->{tag}, 'window', " ... yep" );
ok( $browser->{W}->{id}, " ... yep" );

my $D = $browser->{W}->{zC}[0]{zC}[0]{zC}[0];
is( $D->{tag}, 'textnode', "Found a textnode" )
        or die Dumper $D;
is( $D->{nodeValue}, 'do the following', " ... that's telling me what to do" )
            or die Dumper $D;

my $B1 = $browser->{W}->{zC}[0]{zC}[1];
is( $B1->{tag}, 'button', "Found a button" );

############################################################
$resp = Click( $browser, $B1 );
$data = $browser->decode_resp( $resp, 'click B1' );
$browser->handle_resp( $data, 'click B1' );

is( $D->{nodeValue}, 'You did it!', "The button worked!" )
    or die Dumper $D;

############################################################
my $B2 = $browser->{W}->{zC}[0]{zC}[2];
is( $B2->{tag}, 'button', "Found another button" );

$resp = Click( $browser, $B2 );
$data = $browser->decode_resp( $resp, 'click B2' );
$browser->handle_resp( $data, 'click B2' );

is( $D->{nodeValue}, 'Thank you', "The button is polite" )
    or die Dumper $D;


############################################################
my $other_browser = t::Client->new;
$URI = $other_browser->boot_uri;
$resp = $UA->get( $URI );

$data = $other_browser->decode_resp( $resp, 'boot' );
$other_browser->check_boot( $data );

$other_browser->handle_resp( $data, 'boot' );

ok( $other_browser->{W}, "Got a window" );
is( $other_browser->{W}->{tag}, 'window', " ... yep" );
ok( $other_browser->{W}->{id}, " ... yep" );

isnt( $browser->{SID}, $other_browser->{SID}, "Distinct SID" );
isnt( $browser->{W}{id}, $other_browser->{W}{id}, "Distinct windows" );

my $oD = $other_browser->{W}->{zC}[0]{zC}[0]{zC}[0];
is( $oD->{tag}, 'textnode', "Found a textnode" );
is( $oD->{nodeValue}, 'do the following', " ... that's telling me what to do" );

my $oB1 = $other_browser->{W}->{zC}[0]{zC}[1];
is( $oB1->{tag}, 'button', "Found a button" );

############################################################
$resp = Click( $other_browser, $oB1 );
$data = $other_browser->decode_resp( $resp, 'click oB1' );
$other_browser->handle_resp( $data, 'click oB1' );

is( $oD->{nodeValue}, 'You did it!', "The button worked!" )
        or die Dumper $oD;
isnt( $D->{nodeValue}, $oD->{nodeValue}, "Didn't affect the other browser" )
        or die Dumper $D;


############################################################
$D->{nodeValue} = 'Something';
$resp = Click( $browser, $B2 );
$data = $browser->decode_resp( $resp, 'click B2 again' );
$browser->handle_resp( $data, 'click B2 again' );

is( $D->{nodeValue}, 'Thank you', "The button is polite" );
isnt( $D->{nodeValue}, $oD->{nodeValue}, "Didn't affect the other browser" );


############################################################
# Test application/x-www-form-urlencoded
my $oB2 = $other_browser->{W}->{zC}[0]{zC}[2];
is( $oB2->{tag}, 'button', "Found another button" );
$resp = ClickPost( $other_browser, $oB2 );

$data = $other_browser->decode_resp( $resp, 'click oB2' );
$other_browser->handle_resp( $data, 'click oB2' );

is( $oD->{nodeValue}, 'Thank you', "The button is polite" )
        or die Dumper $oD;

############################################################
# Test application/x-www-form-urlencoded
$resp = ClickJSON( $other_browser, $oB1 );
$data = $other_browser->decode_resp( $resp, 'click oB1 again' );
$other_browser->handle_resp( $data, 'click oB1 again' );

is( $oD->{nodeValue}, 'You did it!', "The button worked!" )
        or die Dumper $oD;


# use Data::Dumper;
# warn Dumper $browser->{W};


############################################################
sub Click 
{
    my( $browser, $button ) = @_;
    my $URI = $browser->Click_uri( $button );
    return $UA->get( $URI );
}

############################################################
sub ClickPost
{
    my( $browser, $button ) = @_;
    my $URI = $browser->base_uri;
    my $args = $browser->Click_args( $button );
    return $UA->post( $URI, $args );
}

############################################################
sub ClickJSON
{
    my( $browser, $button ) = @_;
    my $URI = $browser->base_uri;
    my $req = HTTP::Request->new( POST => $URI );
    $req->content_type( 'application/json' );
    my $args = $browser->Click_args( $button );
    my $json;
    if( $JSON::XS::VERSION > 2 ) {
        $json = JSON::XS::encode_json( $args );
    }
    else {
        $json = JSON::XS::to_json( $args );
    }
    $req->content_length( length $json );
    $req->content( $json );
    return $UA->request( $req );
}



