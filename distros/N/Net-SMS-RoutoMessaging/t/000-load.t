#!/usr/bin/env perl

=pod

=head1 NAME

t/000-load.t - Net::SMS::RoutoMessaging unit tests

=head1 DESCRIPTION

Checks that the main class can be loaded.

=cut

use strict;
use warnings;
use Test::More tests => 2;

use Net::SMS::RoutoMessaging;

ok(1, "Net::SMS::RoutoMessaging v" . Net::SMS::RoutoMessaging->VERSION() . " loaded");

my $sms = Net::SMS::RoutoMessaging->new(
    username => 'testuser',
    password => 'testpass',
);

ok($sms, "Created a Net::SMS::RoutoMessaging object");
