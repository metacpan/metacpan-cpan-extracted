#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;
use Net::Amazon::MechanicalTurk::RowData;

#
# This sample reads the results file and Rejects any rows
# in the file which have a Reject column with an X in it.
#
# This sample demonstrates:
#
# 1. Using the RowData class to iterate through a delimited file.
# 2. Rejecting assignments.
# 3. How to examine the error code from a failed call.
#
# Note: RowData may be used on csv or tab delimited files.
#   The rows are iterated over in the code below, the contents of
#   the file is not read completely into memory.
#

my $mturk = Net::Amazon::MechanicalTurk->new;
my $data  = Net::Amazon::MechanicalTurk::RowData->toRowData("loadhits-results.csv");

$data->each(sub {
    my ($data, $row) = @_;
    my $assignmentId = $row->{AssignmentId};
    # Reject any records that have a reject column with an X in it
    if (exists $row->{Reject} and lc($row->{Reject}) eq 'x') {
        print "Rejecting assignment $assignmentId\n";
        eval {
            $mturk->RejectAssignment( AssignmentId => $assignmentId );
        };
        if ($@) {
            if ($mturk->response->errorCode eq "AWS.MechanicalTurk.InvalidAssignmentState") {
                print "Assignment $assignmentId has already been processed.\n";
            }
            else {
                die $@;
            }
        }
    }
});
