#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;

#
# This sample uses the method loadHITs for bulk loading many hits.
# Data is read from a CSV input file
# which is merged with the question template to produce the xml for the question.
# Each row corresponds to a HIT.
# Progress messages will be printed to the console.
# Successful HITId and HITTypeId's will be printed to a CSV success file.
# Failed rows from the input file will be printed to a CSV failure file.
#

sub questionTemplate {
    my %params = %{$_[0]};
    return <<END_XML;
<?xml version="1.0" encoding="UTF-8"?>
<QuestionForm xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd">
  <Question>
    <QuestionIdentifier>1</QuestionIdentifier>
    <QuestionContent>
      <Text>$params{question}</Text>
    </QuestionContent>
    <AnswerSpecification>
      <FreeTextAnswer/>
    </AnswerSpecification>
  </Question>
</QuestionForm>
END_XML
}

my $properties = {
    Title       => 'LoadHITs Perl sample',
    Description => 'This is a test of the bulk loading API.',
    Keywords    => 'LoadHITs, bulkload, perl, unique1',
    Reward => {
        CurrencyCode => 'USD',
        Amount       => 0.00
    },
    RequesterAnnotation         => 'test',
    AssignmentDurationInSeconds => 60 * 60,
    AutoApprovalDelayInSeconds  => 60 * 60 * 10,
    MaxAssignments              => 3,
    LifetimeInSeconds           => 60 * 60
};

my $mturk = Net::Amazon::MechanicalTurk->new();

$mturk->loadHITs(
    properties => $properties,
    input      => "loadhits-input.csv",
    question   => \&questionTemplate,
    progress   => \*STDOUT,
    success    => "loadhits-success.csv",
    fail       => "loadhits-failure.csv"
);

