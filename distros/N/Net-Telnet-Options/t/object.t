#!/usr/bin/perl -w

use Test::Simple tests => 2;

use Net::Telnet::Options;

my $nto = Net::Telnet::Options->new();

ok(defined($nto),   'new() returned something');
ok($nto->isa('Net::Telnet::Options'), 'created a Net::Telnet::Options object');
