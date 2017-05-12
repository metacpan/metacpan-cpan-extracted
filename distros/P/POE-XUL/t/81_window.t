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

my $pid = t::Server->spawn( $browser->{PORT}, '', 't/window.pl' );
END { kill 2, $pid if $pid; }


diag( "sleep $Q" ) unless $ENV{AUTOMATED_TESTING};
sleep $Q;


############################################################
my $URI = $browser->boot_uri;
my $resp = $UA->get( $URI );
my $data = $browser->decode_resp( $resp, 'boot' );
$browser->check_boot( $data );

$browser->handle_resp( $data, 'boot' );

ok( $browser->{W}, "Got a window" );
is( $browser->{W}->{tag}, 'window', " ... yep" );
ok( $browser->{W}->{id}, " ... yep" );

############################################################
# Test:
#   window->open();

$browser->Click( 'open_it' );

my $D = $browser->find_ID( 'desc' );
is( $D->{tag}, 'description', "Found a description" )
        or die Dumper $D;
$D = $D->{zC}[0];
is( $D->{tag}, 'textnode', "Found a textnode" )
        or die Dumper $D;
is( $D->{nodeValue}, 'Opening a window', " ... that's telling me what it's doing" )
            or die Dumper $D;

my $win2 = $browser->open_window();
ok( $win2, "Got a sub-window" )
        or die "I need that window!";

$win2->Connect();

is( $D->{nodeValue}, 'Opened window sub-window-1', 
                     'Main window was also updated' );

############################################################
# Test:
#   window->close();

$browser->Click( 'close_it' );

is( $win2->{closed}, 1, "Sub-window is closed" );

is( $D->{nodeValue}, 'Close first window', 
                     'Main window was updated' )
        or die "Wait a minute";


############################################################
# Test:
#   window->open(); x 2
#
$browser->Click( 'open_it' );
$win2 = $browser->open_window();
$win2->Connect();
is( $D->{nodeValue}, 'Opened window sub-window-2', 
                     'Main window was also updated' );


$browser->Click( 'open_it' );
my $win3 = $browser->open_window();
ok( $win3, "Got a sub-window" ) or die "I need that window!";
$win3->Connect();
is( $D->{nodeValue}, 'Opened window sub-window-3', 
                     'Main window was also updated' );


$win3->Click( 'close_me3' );
is( $win3->{closed}, 1, "Sub-window-3 is closed" );
is( $win2->{closed}, undef(), "Sub-window-2 isn't closed" );

is( $D->{nodeValue}, 'Closing window sub-window-3', 
                     'Main window was updated' )
        or die "Wait a minute";


############################################################
# Test:
#   $twin = window->open();
#
$browser->Click( 'open_better' );
$win2 = $browser->open_window();
$win2->Connect();
is( $D->{nodeValue}, 'Opening a better window', 
                     'Main window say the Click' );

$D->{nodeValue} = 'not set';

$browser->Click( 'open_better' );
$win3 = $browser->open_window();
$win3->Connect();
is( $D->{nodeValue}, 'Opening a better window', 
                     'Main window say the Click' );



$win3->Close();
is( $win3->{closed}, 1, "$win3->{name} is closed" );
is( $win2->{closed}, undef(), "$win2->{name} isn't closed" );

is( $D->{nodeValue}, 'Closing window POEXUL001', 
                     'Main window was updated' )
        or die "Wait a minute";






pass( "DONE" );

