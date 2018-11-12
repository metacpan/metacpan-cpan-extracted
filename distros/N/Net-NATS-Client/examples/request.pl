#!/usr/bin/perl

use strict;
use warnings;

use Net::NATS::Client;

my $nc = Net::NATS::Client->new(uri => 'nats://0.0.0.0:4222');
$nc->connect() or die $!;

# Setup reply
$nc->subscribe("foo", sub {
    my ($request) = @_;
    printf("Received request: %s\n", $request->data);
    $nc->publish($request->reply_to, "Hello, Human!");
});

# Send request
$nc->request('foo', 'Hello, World!', sub {
    my ($reply) = @_;
    printf("Received reply: %s\n", $reply->data);
});

$nc->wait_for_op for 1..2;
