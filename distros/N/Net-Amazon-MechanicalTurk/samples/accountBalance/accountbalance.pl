#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;

#
# This sample shows how to get your account balance.
#

my $mturk = Net::Amazon::MechanicalTurk->new;
printf "MechanicalTurk account balance: %s\n", $mturk->getAvailableBalance;

