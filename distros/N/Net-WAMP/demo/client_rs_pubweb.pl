#!/usr/bin/env perl

package WAMP_Client;

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/../lib";

use parent qw(
    Net::WAMP::Role::Publisher
    Net::WAMP::Role::Subscriber
);

#----------------------------------------------------------------------

package main;

my $host_port = shift(@ARGV) or die "Need [host:]port!";
substr($host_port, 0, 0) = 'localhost:' if -1 == index($host_port, ':');

if (@ARGV < 2) {
    die "$0 [host:]port name message …\n";
}

use Carp::Always;

use IO::Framed::ReadWrite ();

use Net::WAMP::RawSocket::Client ();

use IO::Socket::INET ();
#my $inet = IO::Socket::INET->new('demo.crossbar.io:80');
my $inet = IO::Socket::INET->new($host_port);
die "[$!][$@]" if !$inet;

$inet->autoflush(1);

my $rs = Net::WAMP::RawSocket::Client->new(
    io => IO::Framed::ReadWrite->new( $inet ),
);

print STDERR "send hs\n";
$rs->send_handshake( serialization => 'json' );
print STDERR "sent hs\n";
$rs->verify_handshake();
print STDERR "vf hs\n";

my $client = WAMP_Client->new(
    serialization => 'json',
    on_send => sub { $rs->send_message($_[0]) },
);

my $got_msg;

sub _receive {
    $got_msg = $rs->get_next_message();
    return $client->handle_message($got_msg->get_payload());
}

$client->send_HELLO( 'com.felipe.demo' );

use Data::Dumper;
print STDERR "RECEIVING …\n";
print Dumper(_receive());
print STDERR "RECEIVED …\n";

utf8::decode($_) for @ARGV;

$client->send_PUBLISH(
    {},
    'com.felipe.demo.chat',
    [ shift(@ARGV), "@ARGV" ],
);

#----------------------------------------------------------------------

1;
