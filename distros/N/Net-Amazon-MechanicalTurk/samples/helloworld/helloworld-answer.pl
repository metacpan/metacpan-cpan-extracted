#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;
use Net::Amazon::MechanicalTurk::XMLParser;
use Net::Amazon::MechanicalTurk::IOUtil;

#
# This sample script displays answers from the hit
# created in helloworld-create.pl.
#
# This sample demonstrates the following features:
#
#  1. Using the GetAssignmentsForHITAll method for iterating all assignments.
#  2. Using the XMLParser to get information out of the Answer XML.
#  3. Using the toString metod to see what is in a response
#      or parsed XML document.
#  4. Using the ApproveAssignment method.
#

# Read the hitid from the text file
sub getHITId {
    my ($file) = @_;
    my $hitid = Net::Amazon::MechanicalTurk::IOUtil->readContents($file);
    chomp($hitid);
    return $hitid;
}


my $mturk = Net::Amazon::MechanicalTurk->new;

# Create an XML parser to go through the Answer
my $parser = Net::Amazon::MechanicalTurk::XMLParser->new;

# look up assignments for the hit
my $hitId = getHITId("hitid.txt");
my $assignments = $mturk->GetAssignmentsForHITAll( HITId => $hitId );
while (my $assignment = $assignments->next) {

    # If you want to see a dump of what is in a response object from an
    # API call, you can use the toString method.
    #print $assignment->toString, "\n";

    my $workerId = $assignment->{WorkerId}[0];
    
    # Parse the answer XML - The answer object returned also has a toString method
    my $answer = $parser->parse($assignment->{Answer}[0]);
    #print $answer->toString, "\n";
    
    my $answerText = $answer->{Answer}[0]{FreeText}[0];
    
    printf "Worker %s said \"%s\"\n", $workerId, $answerText;
    
    if ($assignment->{AssignmentStatus}[0] eq "Submitted") {
        print "Approving the assignment.\n";
        $mturk->ApproveAssignment( AssignmentId => $assignment->{AssignmentId}[0] );
    }
}

