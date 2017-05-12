#!/usr/bin/perl
# $Id: 90_complete.t 1192 2009-02-12 18:38:58Z fil $

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

my $browser = t::Client->new( APP=>'Complete' );

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

############################################################
my $B1 = $browser->get_node( 'B1' );
ok( $B1, "Found the button" );
$resp = Click( $browser, $B1 );
$data = $browser->decode_resp( $resp, 'click B1' );
$browser->handle_resp( $data, 'click B1' );

my $message = $browser->get_node( 'USER-Message' );
my $text = Dumper $message;
ok( ( $text =~ /Clicked button #1/ ), "Clicked OK" );

############################################################
my $B2 = $browser->get_node( 'B2' );
ok( $B2, "Found the button" );
$resp = Click( $browser, $B2 );
$data = $browser->decode_resp( $resp, 'click B2' );
$browser->handle_resp( $data, 'click B2' );

$text = Dumper $message;
ok( ( $text =~ /Clicked button #2/ ), "Clicked OK" );

is( $B2->{label}, "Click #1", "Button updated" );



############################################################
my $TB1 = $browser->get_node( 'TB1' );
ok( $TB1, "Found the first textbox" );

my $B3 = $browser->get_node( 'B3' );
ok( $B3, "Found the third button" );
ok( $B3->{disabled}, " ... it is disabled" );

$TB1->{value} = "Hello world!";
$resp = Change( $browser, $TB1 );
$data = $browser->decode_resp( $resp, 'change TB1' );
$browser->handle_resp( $data, 'change TB1' );

is( $TB1->{value}, '', "First textbox was emptied" );

my $TB2 = $browser->get_node( 'TB2' );
ok( $TB2, "Found the second textbox" );
is( $TB2->{value}, "Hello world!", " ... it was updated" );

ok( !$B3->{disabled}, "Third button was enabled" );

$resp = Click( $browser, $B3 );
$data = $browser->decode_resp( $resp, 'click B3' );
$browser->handle_resp( $data, 'click B3' );

$text = Dumper $message;
ok( ( $text =~ /Hello world!/ ), "Clicked OK" );
is( $TB1->{value}, '', "Second textbox was emptied" );


############################################################
# Test javascript and CDATA
my $AB = $browser->get_node( 'alert-button' );
ok( $AB, "Found the alert-button" ) 
        or die "I really need that button";

$resp = Click( $browser, $AB );
$data = $browser->decode_resp( $resp, 'click alert-button' );
$browser->handle_resp( $data, 'click alert-button' );

my $JS = $browser->{W}->{zC}[-1];
ok( ($JS and $JS->{type} eq 'text/javascript'), "Found the javascript" ) 
        or die "I really need that javascript";
my $code = delete $JS->{zC}[0]{cdata};
ok( ($code =~ /alert/), "Got the javascript" )
        or die $JS;

############################################################
# Test menulist
my $ML = $browser->get_node( 'ML1' );
ok( $ML, "Got the menulist" );

die Dumper $ML unless $ML->{zC};

$ML->{selectedIndex} = 2;       # Bears
$resp = Select( $browser, $ML );
$data = $browser->decode_resp( $resp, 'select bears' );
$browser->handle_resp( $data, 'select bears' );

is( $ML->{selectedIndex}, 2, "Bears were selected" );
my $I = $ML->{zC}[0]{zC}[ $ML->{selectedIndex} ];
ok( $I, "Found the selected item" );
is( $I->{label}, "Bears", " ... and it's bears" )
        or die Dumper $ML;

my $other;

SKIP: {
    skip "Side-effects no longer echoed back to browser", 2;
    ok( $I->{selected}, " ... and it's selected" )
            or die Dumper $ML;

    $other = $ML->{zC}[0]{zC}[ 0 ];
    ok( !$other->{selected}, " ... and the other one isn't" )
            or die Dumper $ML;
}

###########
$ML->{selectedIndex} = 0;       # Lions
$resp = Select( $browser, $ML );
$data = $browser->decode_resp( $resp, 'select lions' );
$browser->handle_resp( $data, 'select lions' );

is( $ML->{selectedIndex}, 0, "Lions were selected" );
$I = $ML->{zC}[0]{zC}[ $ML->{selectedIndex} ];
ok( $I, "Found the selected item" );
is( $I->{label}, "Lions", " ... and it's lions" )
        or die Dumper $ML;

SKIP: {
    skip "Side-effects no longer echoed back to browser", 2;
    ok( $I->{selected}, " ... and it's selected" )
        or die Dumper $ML;

    $other = $ML->{zC}[0]{zC}[ 2 ];
    ok( !exists $other->{selected}, " ... and the other one isn't" )
        or die Dumper $ML;
}



############################################################
# Test textnode manipulation
my $MC = $browser->get_node( 'message-clear' );

ok( $MC, "Found the Clear button" )
                or die "We need that button!";
$resp = Click( $browser, $MC );
$data = $browser->decode_resp( $resp, 'clear messages' );

$browser->handle_resp( $data, 'clear messages' );

$text = Dumper $message;

my $count = () = ($text =~ /nodeValue/g);
is( $count, 1, "Only one message" )
            or die $text, Dumper $resp;
ok( ($text =~ /hello world/), " ... and it's the one we want" )
            or die $text;



############################################################
# Test radio buttons
my $RG1 = $browser->get_node( 'RG1' );
ok( $RG1, "Got the radiogroup" );

$resp = RadioClick( $browser, $RG1, 0 );
$data = $browser->decode_resp( $resp, 'orange' );
$browser->handle_resp( $data, 'orange' );

#########
$text = Dumper $message;

$count = () = ($text =~ /nodeValue/g);
is( $count, 2, "Two messages" )
            or die $text;
ok( ($text =~ /Orange/), " ... and one we want" )
            or die $text;
# CSS updated
ok( ($text =~/background-color: orange;/), " ... it's in orange" );

#########
my $R = RadioSelected( $RG1 );
is( $R->{label}, 'Orange', "I like orange" );

#########
$resp = RadioClick( $browser, $RG1, 1 );
$data = $browser->decode_resp( $resp, 'violet' );
$browser->handle_resp( $data, 'violet' );

#########
$text = Dumper $message;

$count = () = ($text =~ /nodeValue/g);
is( $count, 3, "Two messages" )
            or die $text;
ok( ($text =~ /Violet/), " ... and one we want" )
            or die $text;
# CSS updated
ok( ($text =~/background-color: violet;/), " ... it's in violet" );

#########
$R = RadioSelected( $RG1 );
SKIP: {
    skip "Side-effects no longer echoed back to browser", 1;
    is( $R->{label}, 'Violet', "Start wearing purple all the time" );
}

#########


$JS = $browser->{W}->{zC}[-1];
ok( $JS, "Found the javascript" ) 
        or die "I really need that javascript";
is( $JS->{type}, 'text/javascript', "Found the javascript" ) 
        or die Dumper $JS;
$code = $JS->{zC}[0]{cdata};
ok( !$code, "Didn't get more javascript" )
        or die Dumper $JS;



############################################################
# Test listbox
my $SB = $browser->get_node( 'SB1' );
ok( $SB, "Got the listbox" );

die Dumper $SB unless $SB->{zC};

my $Cosmo = $SB->{zC}[5];           # Cosmo 3 + listcols + listheaders
$SB->{selectedIndex} = 3;
$resp = Select( $browser, $SB );
$data = $browser->decode_resp( $resp, 'select Cosmo' );
$browser->handle_resp( $data, 'select Cosmo' );

SKIP: {
    skip "Side-effects no longer echoed back to browser", 1;
    is( $Cosmo->{selected}, 'true', "Cosmo was selected" );
}

$text = Dumper $message;

$count = () = ($text =~ /Cosmo-Female-White/g);
is( $count, 1, "Got the one message" )
            or die $text;

#########
my $Butter = $SB->{zC}[11];           # Butter 9 + listcols + listheaders
$SB->{selectedIndex} = 9;
$resp = Select( $browser, $SB );
$data = $browser->decode_resp( $resp, 'select Butter' );
$browser->handle_resp( $data, 'select Butter' );

SKIP: {
    skip "Side-effects no longer echoed back to browser", 2;
    is( $Butter->{selected}, 'true', "Butter was selected" );
    is( $Cosmo->{selected}, undef(), " ... and cosmo isn't" );
}
$text = Dumper $message;

$count = () = ($text =~ /Butter-Male-Orange/g);
is( $count, 1, "Got the one message" )
            or die $text;







############################################################
sub Click 
{
    my( $browser, $button ) = @_;
    my $URI = $browser->Click_uri( $button );
    return $UA->get( $URI );
}

############################################################
sub Change
{
    my( $browser, $textbox ) = @_;
    my $URI = $browser->base_uri;
    my $args = $browser->Change_args( $textbox );
    return $UA->post( $URI, $args );
}

############################################################
sub Select
{
    my( $browser, $ML ) = @_;
    my $URI = $browser->base_uri;
    my $args = $browser->Select_args( $ML );
    return $UA->post( $URI, $args );
}

############################################################
sub RadioClick
{
    my( $browser, $RG, $index ) = @_;
    my $URI = $browser->base_uri;
    my $args = $browser->RadioClick_args( $RG, $index );
    return $UA->post( $URI, $args );
}

# Find which radio button is checked
sub RadioSelected
{
    my( $RG ) = @_;
    my $sel;
    foreach my $R ( @{ $RG->{zC} } ){
        next unless $R->{selected};
        ok( !$sel, "Only one radio selected" );
        $sel = $R;
    }
    ok( $sel, "Found a selected radio" )
        or die Dumper $RG;
    return $sel;
}




