#!/usr/bin/perl

use strict;
use warnings;

use Benchmark qw(:all);
use Net::NATS::Client;

my $client = Net::NATS::Client->new(uri => 'nats://localhost:4222');
$client->connect() or die $!;

timethis (-10, sub { $client->publish("benchmark", "test"); });
