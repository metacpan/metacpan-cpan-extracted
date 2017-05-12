#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;
use Net::Amazon::MechanicalTurk::IOUtil;

my $question = "What is the weather like right now in Seattle, WA?";

my $questionXml = <<END_XML;
<?xml version="1.0" encoding="UTF-8"?>
<QuestionForm xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd">
  <Question>
    <QuestionIdentifier>1</QuestionIdentifier>
    <QuestionContent>
      <Text>$question</Text>
    </QuestionContent>
    <AnswerSpecification>
      <FreeTextAnswer/>
    </AnswerSpecification>
  </Question>
</QuestionForm>
END_XML


my $mturk = Net::Amazon::MechanicalTurk->new;

my $result = $mturk->CreateHIT(
    Title       => 'Answer a question',
    Description => 'Test HIT from Perl',
    Keywords    => 'hello, world, command, sample',
    Reward => {
        CurrencyCode => 'USD',
        Amount       => 0.00
    },
    RequesterAnnotation         => 'Test Hit',
    AssignmentDurationInSeconds => 60 * 60,
    AutoApprovalDelayInSeconds  => 60 * 60 * 10,
    MaxAssignments              => 1,
    LifetimeInSeconds           => 60 * 60,
    Question                    => $questionXml
);

printf "Created HIT:\n";
printf "HITId:     %s\n", $result->{HITId}[0];
printf "HITTypeId: %s\n", $result->{HITTypeId}[0];

printf "\nYou may see your hit here: %s\n", $mturk->getHITTypeURL($result->{HITTypeId}[0]);

# Write out the HITId to a text file in order to get 
# the answer in the helloworld-answer.pl script.
Net::Amazon::MechanicalTurk::IOUtil->writeContents(
    "hitid.txt", $result->{HITId}[0]
);
