#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;
use XML::Parser;

#
# This script loadsHITs using custom code to generate rows.
# The rows are generated from an XML file using event driven parsing.
# See loadhits2.pl, to see how to load hits using an in memory array
# of hashes for input.
#
# This script demonstrates the following features:
#   1. Using loadHITs for bulk loading.
#   2. Using XML::Parser for event based parsing.
#   3. Using a subroutine for generating input and passing
#      rows back to the loading process.
#

sub questionTemplate {
    my %params = %{$_[0]};
    return <<END_XML;
<?xml version="1.0" encoding="UTF-8"?>
<QuestionForm xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd">
  <Question>
    <QuestionIdentifier>1</QuestionIdentifier>
    <QuestionContent>
      <Text>Have you ever lived in $params{city}, $params{state}?</Text>
    </QuestionContent>
    <AnswerSpecification>
      <FreeTextAnswer/>
    </AnswerSpecification>
  </Question>
</QuestionForm>
END_XML
}

sub generateData {
    my ($xmlfile, $handler) = @_;
    my $parser = XML::Parser->new;
    $parser->setHandlers(
        Start => sub {
            my ($parser, $element, %attrs) = @_;
            if ($element eq "city") {
                # Tell the handler you have a row for it to create a hit with.
                $handler->({
                    city  => $attrs{name},
                    state => $attrs{state}
                });
            }
        }
    );
    $parser->parsefile($xmlfile);
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

my $xmlfile = "cities.xml";
my $mturk = Net::Amazon::MechanicalTurk->new;

$mturk->loadHITs(
    properties => $properties,
    input      => sub { generateData($xmlfile, @_) },
    question   => \&questionTemplate,
    progress   => \*STDOUT,
    success    => "loadhits-success.csv",
    fail       => "loadhits-failure.csv"
);


