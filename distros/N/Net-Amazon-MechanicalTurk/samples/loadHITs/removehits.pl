#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;
use Net::Amazon::MechanicalTurk::RowData;

#
# This samples goes through the success file and tries
# to remove all contained HITs from MechanicalTurk including 
# auto approving any Submitted assignments.
# 
# This script demonstrates the following features:
#
# 1. Reading and processing a success file with the RowData class.
# 2. Using the deleteHIT convenience method.
# 3. Catching errors using eval.
#

my $mturk = Net::Amazon::MechanicalTurk->new;
my $data = Net::Amazon::MechanicalTurk::RowData->toRowData("loadhits-success.csv");

my $autoApprove = 1;

$data->each(sub {
    my ($data, $row) = @_;
    my $hitId = $row->{HITId};
    
    printf "Deleting hit $hitId\n";
    eval {
        $mturk->deleteHIT($hitId, $autoApprove);
    };
    if ($@) {
        warn "Couldn't delete hit $hitId - " . $mturk->response->errorCode . "\n";
    }
   
});

