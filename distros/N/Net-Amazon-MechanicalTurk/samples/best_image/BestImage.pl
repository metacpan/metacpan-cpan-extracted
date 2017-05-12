#!/usr/bin/perl
use strict;
use warnings;
use IO::File;
use Net::Amazon::MechanicalTurk;
use Net::Amazon::MechanicalTurk::Properties;
use Net::Amazon::MechanicalTurk::IOUtil;

#
# This sample reads in a properties file into a nested 
# data structure, which may be used to create a hit.
#

# Read the properties into a nested data structure
my $hitProperties = Net::Amazon::MechanicalTurk::Properties->readNestedData(
    "best_image.properties"
);

# Read the question file in
my $question = Net::Amazon::MechanicalTurk::IOUtil->readContents(
    "best_image.question"
);

# Put the question into the hitProperties
$hitProperties->{Question} = $question;

my $mturk = Net::Amazon::MechanicalTurk->new;
my $hit = $mturk->CreateHIT($hitProperties);

print "Created HIT.\n";
print $hit->toString, "\n";

printf "\nYou may see your hit here: %s\n", $mturk->getHITTypeURL($hit->{HITTypeId}[0]);

