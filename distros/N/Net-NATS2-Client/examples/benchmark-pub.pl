#!/usr/bin/perl

use strict;
use warnings;

use Benchmark qw(:all);
use Net::NATS2::Client;

my $client = Net::NATS2::Client->new(uri => 'nats://localhost:4222');
$client->connect() or die $!;

timethis (-10, sub { $client->publish("benchmark", "test"); });
