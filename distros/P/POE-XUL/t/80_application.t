#!/usr/bin/perl
# $Id$

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

my $UA = LWP::UserAgent->new;
$UA->timeout( $Q * 24 );

my $browser = t::Client->new( UA => $UA );

my $pid = t::Server->spawn( $browser->{PORT}, '', 't/application.pl' );
END { kill 2, $pid if $pid; }


diag( "sleep $Q" ) unless $ENV{AUTOMATED_TESTING};
sleep $Q;


############################################################
# Test:
#   - Session->_invoke_state 
#   - Window sets {main_window} and App::window()
#   - $app->boot w/o Node::Boot()
my $URI = $browser->boot_uri;
my $resp = $UA->get( $URI );
my $data = $browser->decode_resp( $resp, 'boot' );
$browser->check_boot( $data );

$browser->handle_resp( $data, 'boot' );

ok( $browser->{W}, "Got a window" );
is( $browser->{W}->{tag}, 'window', " ... yep" );
ok( $browser->{W}->{id}, " ... yep" );

my $D = $browser->find_ID( 'desc' );
is( $D->{tag}, 'description', "Found a description" )
        or die Dumper $D;
$D = $D->{zC}[0];
is( $D->{tag}, 'textnode', "Found a textnode" )
        or die Dumper $D;
is( $D->{nodeValue}, 'do the following', " ... that's telling me what to do" )
            or die Dumper $D;

############################################################
# Test
#   - window->getElementById
#   - {main_window}
#   - default for an event handler is that it has done(1)
my $B1 = $browser->find_ID( 'button' );
is( $B1->{tag}, 'button', "Found a button" );

$browser->Click( $B1 );

is( $D->{nodeValue}, 'You did it!', "The button worked!" )
    or die Dumper $D;

############################################################
# Test event->defer + event->handled
my $B2 = $browser->find_ID( 'button2' );
is( $B2->{tag}, 'button', "Found another button" );

$browser->Click( $B2 );

is( $D->{nodeValue}, 'Thank you', "The button is polite" )
    or die Dumper $D;


############################################################
# This tests
#   - server->attach_event 
#   - server->event_error
my $BU = $browser->find_ID( 'blow_up' );
ok( $BU, "Found button" )
            or die "I really need that button";
$URI = $browser->Click_uri( $BU );
$resp = $UA->get( $URI );
$data = $browser->decode_resp( $resp, "Click $BU->{id}" );
is( $data->[0][0], 'ERROR', 'It blew up!' )
        or warn "resp=", Dumper $resp;
ok( ($data->[0][2] =~ m(^PERL ERROR: Kabooom! at t/application.pl line \d+.) ), 
        "An earth shattering kaboom" )
            or warn $data->[0][2];
# warn Dumper $data;

############################################################
# This tests:
#   - Node->attach and server->attach_event for an xul_Event_id() function
#   - defer + yield + handled
$browser->Click( 'honk' );

is( $D->{nodeValue}, 'honk honk', "honk honk" )
    or die Dumper $D;

############################################################
# This tests:
#   - Button( ...., 'Click' );
$browser->Click( 'HONK' );

is( $D->{nodeValue}, 'HONK HONK', "HONK HONK" )
    or die Dumper $D;











pass( "DONE" );

