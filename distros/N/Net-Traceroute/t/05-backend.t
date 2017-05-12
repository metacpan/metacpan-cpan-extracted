#!/usr/bin/perl

# Ensure that the backend argument to new performs as expected.
# This is a promised interface for other traceroute backends.

use strict;
use warnings;

use Test::More tests => 4;

use Net::Traceroute;

# Will be set in our test backend to ensure that the code really
# executed.
our $really_used;

package Net::Traceroute::TestBackend;

use base qw(Net::Traceroute);

sub new {
    $main::really_used = 1;
    bless {}, "Net::Traceroute::TestBackend";
}

package Net::Traceroute::BrokenBackend;

use base qw(Net::Traceroute);

package main;

my $tr = Net::Traceroute->new(backend => "TestBackend");

isa_ok($tr, "Net::Traceroute::TestBackend", "Net::Traceroute returned our test backend");
is($really_used, 1, "constructor set our 'used' variable");

eval { Net::Traceroute->new(backend => "BrokenBackend"); };
ok(defined($@), "broken backend died");

my $trp = Net::Traceroute->new(backend => "Parser");
is(ref($trp), "Net::Traceroute", "backend => Parser gets a Net::Traceroute");
