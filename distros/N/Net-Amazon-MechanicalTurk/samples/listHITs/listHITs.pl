#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;
use Net::Amazon::MechanicalTurk::DelimitedWriter;

#
# This sample downloads your HITs from MechanicalTurk and writes
# the HITId's, HITTypeId's, Statuses and Titles to a CSV file.
#
# This sample demonstrates:
#   1. Using the SearchHITsAll method to iterate through HITs.
#   2. Using the DelimitedWriter class to write a CSV.
#      It will properly quote fields containing new lines and commas.
#      Quotes will also be escaped using double quotes.
#

my $out = Net::Amazon::MechanicalTurk::DelimitedWriter->new(
    fieldSeparator => ",",
    file           => "hits.csv"
);

# fields I am interested in
my @fields = qw{
    HITId
    HITTypeId
    HITStatus
    Title
};

$out->write(@fields);

my $mturk = Net::Amazon::MechanicalTurk->new;
my $hits = $mturk->SearchHITsAll;
my $count = 0;
while (my $hit = $hits->next) {
    my @row;
    foreach my $field (@fields) {
        push(@row, $hit->{$field}[0]);
    }
    $out->write(@row);
    $count += 1;
}

$out->close;

print "Wrote " . $count . "hit lines into hits.csv" . "\n";
