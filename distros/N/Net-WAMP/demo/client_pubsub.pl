#!/usr/bin/env perl

package main;

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/../lib";

my $host_port = $ARGV[0] or die "Need [host:]port!";
substr($host_port, 0, 0) = 'localhost:' if -1 == index($host_port, ':');

use Carp::Always;

use HTTP::Response ();
use IO::Framed::ReadWrite ();

use Net::WebSocket::Endpoint::Client ();
use Net::WebSocket::Frame::text ();
use Net::WebSocket::Handshake::Client ();
use Net::WebSocket::Parser ();

use JSON;
use Socket ();

use Types::Serialiser ();
use IO::Socket::INET ();

my $inet = IO::Socket::INET->new($host_port);
die "$host_port - [$!][$@]" if !$inet;

$inet->autoflush(1);

my $iof = IO::Framed::ReadWrite->new($inet);

#----------------------------------------------------------------------

my $hsk = Net::WebSocket::Handshake::Client->new(
    uri => 'wss://demo.crossbar.io/ws',
    subprotocols => [ 'wamp.2.json' ],
);

$inet->syswrite( $hsk->create_header_text() . "\x0d\x0a" );

my $buf;

while (1) {
    recv( $inet, $buf, 32768, Socket::MSG_PEEK() ) or do { die $! if $! };
    last if $buf =~ m<\A(.+?)\x0d\x0a\x0d\x0a>s;
}

sysread( $inet, $buf, 4 + length($buf) ) or die $!;
my $resp = HTTP::Response->parse( $buf );

$hsk->validate_accept_or_die( $resp->header('Sec-WebSocket-Accept') );

print STDERR "WebSocket handshake ok\n";

#XXX Flagrantly ignoring the HTTP response otherwise …

my $ept = Net::WebSocket::Endpoint::Client->new(
    parser => Net::WebSocket::Parser->new( $iof ),
    out => $iof,
);

#----------------------------------------------------------------------

my $client = WAMP_Client->new(
    serialization => 'json',
    on_send => sub {
        my $frm = Net::WebSocket::Frame::text->new(
            $ept->FRAME_MASK_ARGS(),
            payload_sr => \$_[0],
        );
        $iof->write( $frm->to_bytes());
    },
);

$client->send_HELLO(
    'felipes_demo', #'myrealm',
);

use Data::Dumper;
print Dumper($client->handle_message( $ept->get_next_message()->get_payload() ));

#----------------------------------------------------------------------

print STDERR "Subscribing …\n";
$client->send_SUBSCRIBE( {}, 'com.myapp.hello' );
print STDERR "sent subscribe\n";
print Dumper($client->handle_message($ept->get_next_message()->get_payload()));

$client->send_PUBLISH(
    {
        acknowledge => Types::Serialiser::true(),
        exclude_me => Types::Serialiser::false(),
    },
    'com.myapp.hello',
    ['Hello, world! This is my published message.'],
);

#PUBLISHED
print Dumper($client->handle_message($ept->get_next_message()->get_payload()));

#EVENT
print Dumper($client->handle_message($ept->get_next_message()->get_payload()));

#----------------------------------------------------------------------

package WAMP_Client;

use parent qw(
    Net::WAMP::Role::Publisher
    Net::WAMP::Role::Subscriber
);

#----------------------------------------------------------------------


1;
