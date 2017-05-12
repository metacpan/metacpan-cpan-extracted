#!/usr/bin/perl
# $Id: 61_error.t 1566 2010-11-03 03:13:32Z fil $

use strict;
use warnings;

use Data::Dumper;
use POE::Component::XUL;
use HTTP::Status;
use JSON::XS;

use constant DEBUG=>0;

use t::PreReq;
use Test::More ( tests=> 8 );
t::PreReq::load( 8, qw( HTTP::Request LWP::UserAgent ) );

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

unless( $ENV{AUTOMATED_TESTING} ) {
    diag( "" );
    diag( "" );
    diag( "We are testing several error conditions.  Because of this you" );
    diag( "might see some error messages.  These may be ignored." );
    diag( "" );
}

diag( "sleep $Q" ) unless $ENV{AUTOMATED_TESTING};
sleep $Q;

my $UA = LWP::UserAgent->new;

$UA->timeout( 2*60 );

############################################################
# Bad HTTP method
my $URI = $browser->root_uri;
my $resp = $UA->post( $URI );

is( $resp->code, RC_METHOD_NOT_ALLOWED, "Can't POST to root" )
        or die Dumper $resp;
is( $resp->content_type, 'text/plain', " ... and it's a plain text" );
ok( ($resp->content =~ /POST/), " ... and it looks OK" )
        or warn "error=", $resp->content;
ok( $resp->content_length, " ... seems big enough" );

############################################################
# Unknown file
$URI = $browser->root_uri;
$URI->path( 'HONK/bonk/ZONK' );
$resp = $UA->get( $URI );

is( $resp->code, RC_NOT_FOUND, "Can't find that silly file" )
        or die Dumper $resp;
is( $resp->content_type, 'text/html', " ... and it's an HTML response" );
ok( ($resp->content =~ /ZONK/), " ... and it looks OK" )
        or warn "error=", $resp->content;
ok( $resp->content_length, " ... seems big enough" );

############################################################
# Request, but path isn't /xul
if( 0 ) {
    # POE::Component::Server::HTTP routes this request to / anyway
    $URI = $browser->boot_uri;
    $URI->path( '/xul/honk/bonk' );
    $resp = $UA->get( $URI );

    is( $resp->code, RC_NOT_FOUND, "Doesn't like the URI" )
            or die Dumper $resp;
    is( $resp->content_type, 'text/plain', " ... and it's a plain text response" );
    ok( ($resp->content =~ /bonk/), " ... and it looks OK" )
            or warn "error=", $resp->content;
    ok( $resp->content_length, " ... seems big enough" );

    warn $resp->content;
}

