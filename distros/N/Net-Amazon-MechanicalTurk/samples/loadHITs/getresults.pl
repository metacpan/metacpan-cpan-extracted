#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;

#
# This sample shows how to download results for the HITs
# contained in a success file.
#

my $mturk = Net::Amazon::MechanicalTurk->new;

$mturk->retrieveResults(
    input    => "loadhits-success.csv",
    output   => "loadhits-results.csv",
    progress => \*STDOUT
);

