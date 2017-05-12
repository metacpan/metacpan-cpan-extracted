#!/usr/bin/env perl

=pod

=head1 NAME

t/000-load.t - Net::SMS::CSNetworks unit tests

=head1 DESCRIPTION

Checks that the main class can be loaded.

=cut

use strict;
use warnings;
use Test::More tests => 2;

use Net::SMS::CSNetworks;

ok(1, "Net::SMS::CSNetworks v" . Net::SMS::CSNetworks->VERSION() . " loaded");

my $sms = Net::SMS::CSNetworks->new(
    username => 'testuser',
    password => 'testpass',
);

ok($sms, "Created a Net::SMS::CSNetworks object");
