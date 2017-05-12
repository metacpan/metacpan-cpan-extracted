#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;
use Net::Amazon::MechanicalTurk::XMLParser;

#
# This script loadsHITs using an array of hashes in memory.
#
# This script demonstrates the following features:
#   1. Using loadHITs for bulk loading.
#   2. Using Net::Amazon::MechanicalTurk::XMLParser to convert an XML document
#      into a perl data structure.
#   3. Loading hits with an array of hashes as input.
#

sub questionTemplate {
    my %params = %{$_[0]};
    return <<END_XML;
<?xml version="1.0" encoding="UTF-8"?>
<QuestionForm xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd">
  <Question>
    <QuestionIdentifier>1</QuestionIdentifier>
    <QuestionContent>
      <Text>How many people live in $params{city}, $params{state}?</Text>
    </QuestionContent>
    <AnswerSpecification>
      <FreeTextAnswer/>
    </AnswerSpecification>
  </Question>
</QuestionForm>
END_XML
}

my $properties = {
    Title       => 'LoadHITs hits from custom code.',
    Description => 'This is a test of the bulk loading API.',
    Keywords    => 'LoadHITs, bulkload',
    Reward => {
        CurrencyCode => 'USD',
        Amount       => 0.00
    },
    RequesterAnnotation         => "Test",
    AssignmentDurationInSeconds => 60 * 60,
    AutoApprovalDelayInSeconds  => 60 * 60 * 10,
    MaxAssignments              => 3,
    LifetimeInSeconds           => 60 * 60
};

# Load cities.xml into an array of hashes with the fields
#  city and state.
my @cities;
my $xml = Net::Amazon::MechanicalTurk::XMLParser->new->parseFile("cities.xml");
foreach my $cityElement (@{$xml->{city}}) {
    push(@cities, {
        city  => $cityElement->{name}[0],
        state => $cityElement->{state}[0],
    });
}

my $mturk = Net::Amazon::MechanicalTurk->new;

$mturk->loadHITs(
    properties => $properties,
    input      => \@cities,
    question   => \&questionTemplate,
    progress   => \*STDOUT,
    success    => "loadhits-success.csv",
    fail       => "loadhits-failure.csv"
);


