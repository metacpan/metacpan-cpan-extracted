#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;

# This sample tries to remove all hits and assignments from
# your account.  Any hits which have been submitted will be approved.
# This code demonstrates the following features:
#
#     1. Using the SearchHITsAll method to iterate through HITs.
#     2. Using the convenience method deleteHIT.
#

sub confirmWipe {
    my ($mturk) = @_;
    my $answer;
    $|=1;
    while (1) {
        print "Are you sure you want to wipe all hits from MechanicalTurk?\n",
              "All outstanding assignments will be approved.\n",
              "Operations will run against ", $mturk->serviceUrl, "\n\n";
        print "[yes/no] ";
        $answer = <STDIN>;
        chomp($answer);
        $answer = lc($answer);
        last if ($answer =~ /^(yes|no)$/);
    }
    return ($answer eq "yes");
}

my $mturk = Net::Amazon::MechanicalTurk->new();
exit 0 unless confirmWipe($mturk);
    
# Try and remove all hits
print "Expiring and disposing all hits.....\n";
my $hits = $mturk->SearchHITsAll;
my $autoApprove = 1;

while (my $hit = $hits->next) {
    my $hitId = $hit->{HITId}[0];
    print "Deleting hit $hitId\n";
    eval {
        $mturk->deleteHIT($hitId, $autoApprove);
    };
    warn $@ if $@;
}
