#!/usr/bin/env perl

=pod

=head1 NAME

t/000-load.t - Net::SMS::Mach unit tests

=head1 DESCRIPTION

Checks that the main class can be loaded.

=cut

use strict;
use warnings;
use Test::More tests => 2;

use Net::SMS::Mach;

ok(1, "Net::SMS::Mach v" . Net::SMS::Mach->VERSION() . " loaded");

my $sms = Net::SMS::Mach->new(
    userid => '12345',
    password => 'testpass',
);

ok($sms, "Created a Net::SMS::Mach object");
