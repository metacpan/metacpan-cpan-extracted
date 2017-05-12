#!/usr/bin/env perl

package main;

use Data::Dumper;
use IO::Socket::INET ();
use JSON ();
use Types::Serialiser ();

use IO::Framed::ReadWrite ();

use FindBin;
use lib "$FindBin::Bin/../lib";

use Net::WAMP::RawSocket::Client ();

my $host_port = $ARGV[0] or die "Need [host:]port!";
substr($host_port, 0, 0) = 'localhost:' if -1 == index($host_port, ':');

my $inet = IO::Socket::INET->new($host_port);
die "[$!][$@]" if !$inet;

$inet->autoflush(1);

my $rs = Net::WAMP::RawSocket::Client->new(
    io => IO::Framed::ReadWrite->new( $inet ),
);

#print STDERR "send hs\n";
$rs->send_handshake( serialization => 'json' );

#print STDERR "sent hs\n";
$rs->verify_handshake();

my $client = WAMP_Client->new(
    serialization => 'json',
    on_send => sub { $rs->send_message($_[0]) },
);

my $got_msg;

sub _receive {
    $got_msg = $rs->get_next_message();
    return $client->handle_message($got_msg->get_payload());
}

$client->send_HELLO( 'felipes_demo' ); #'myrealm',

print STDERR "RECEIVING …\n";
print Dumper(_receive());
print STDERR "RECEIVED …\n";

#----------------------------------------------------------------------

$client->send_SUBSCRIBE( {}, 'com.myapp.hello' );
print STDERR "sent subscribe\n";
print Dumper(_receive());

$client->send_PUBLISH(
    {
        acknowledge => Types::Serialiser::true(),
        exclude_me => Types::Serialiser::false(),
    },
    'com.myapp.hello',
    ['Hello, world! This is my published message.'],
);

#EVENT
print Dumper(_receive());

#PUBLISHED
print Dumper(_receive());

#----------------------------------------------------------------------

package WAMP_Client;

use strict;
use warnings;
use autodie;

use parent qw(
    Net::WAMP::Role::Publisher
    Net::WAMP::Role::Subscriber
);

1;
