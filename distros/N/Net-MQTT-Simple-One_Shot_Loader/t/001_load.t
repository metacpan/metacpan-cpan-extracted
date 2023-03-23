#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;
BEGIN { require_ok('Net::MQTT::Simple::One_Shot_Loader') };
BEGIN { use_ok('Net::MQTT::Simple') };
BEGIN { use_ok('Net::MQTT::Simple::SSL') };


my $host = 'mqtt';
my $mqtt = Net::MQTT::Simple->new($host);
can_ok($mqtt, 'one_shot');

my $mqtt2 = Net::MQTT::Simple::SSL->new($host);
can_ok($mqtt2, 'one_shot');
