#!/usr/bin/perl

use strict;
use warnings;

use Net::NATS::Client;

my $nc1 = Net::NATS::Client->new(uri => 'nats://0.0.0.0:4222');
$nc1->connect() or die $!;

my $nc2 = Net::NATS::Client->new(uri => 'nats://0.0.0.0:4222');
$nc2->connect() or die $!;

$nc1->subscribe('foo', sub {
    my ($message) = @_;
    print $message->data . "\n";    
});

# TODO: Sometimes the publish happens before the subscribe.  socket buffering?

$nc2->publish('foo', 'Hello, World!');

$nc1->wait_for_op();
