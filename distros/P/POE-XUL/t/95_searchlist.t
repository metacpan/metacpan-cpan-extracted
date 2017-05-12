#!/usr/bin/perl -w

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

############################################################
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

