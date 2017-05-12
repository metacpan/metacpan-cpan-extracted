#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN { push(@INC, "lib", "t"); }
use Net::Amazon::MechanicalTurk;
use Net::Amazon::MechanicalTurk::Command::LoadHITs;
use Net::Amazon::MechanicalTurk::Command::UpdateHITs;
use TestHelper;

my $mturk = TestHelper->new;

if (!$ENV{MTURK_TEST_WRITABLE}) {
    plan skip_all => "Set environment variable MTURK_TEST_WRITABLE=1 to enable tests which have side-effects.";
}
else {
    plan tests => 1;
}

sub renderQuestion {   
    my ($params) = @_;
    return <<END_XML;
<?xml version="1.0" encoding="UTF-8"?>
<QuestionForm xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd">
  <Question>
    <QuestionIdentifier>1</QuestionIdentifier>
    <QuestionContent>
      <Text>$params->{question}</Text>
    </QuestionContent>
    <AnswerSpecification>
      <FreeTextAnswer/>
    </AnswerSpecification>
  </Question>
</QuestionForm>
END_XML
}

my $hitInput = [
    { question => 'Where are you now?' },
    { question => 'Where were you yesterday?' },
    { question => 'What is your name?' },
];

my $properties = {
    Title       => 'Answer a question',
    Description => 'Test HIT from Perl',
    Keywords    => 'hello, world, command, sample',
    Reward => {
        CurrencyCode => 'USD',
        Amount       => 0.01
    },
    RequesterAnnotation         => 'Test Hit',
    AssignmentDurationInSeconds => 60 * 60,
    AutoApprovalDelayInSeconds  => 60 * 60 * 10,
    MaxAssignments              => 3,
    LifetimeInSeconds           => 60 * 60
};

my $properties2 = {
    Title       => 'Answer a revised question',
    Description => 'Test HIT from Perl',
    Keywords    => 'hello, world, command, sample, changehittypeofhit',
    Reward => {
        CurrencyCode => 'USD',
        Amount       => 0.02
    },
    RequesterAnnotation         => 'Test Hit',
    AssignmentDurationInSeconds => 60 * 60,
    AutoApprovalDelayInSeconds  => 60 * 60 * 10,
};

$mturk->loadHITs(
    properties => $properties,
    input      => $hitInput,
    question   => \&renderQuestion,
    #progress   => \*STDERR,
    success    => "t/data/78.generatedhits.txt",
    fail       => "t/data/78.failed.txt"
);

$mturk->updateHITs(
    properties => $properties2,
    input      => "t/data/78.generatedhits.txt",
    #progress   => \*STDERR,
    success    => "t/data/78.updatedhits.txt",
    fail       => "t/data/78.updatefailed.txt",
);

ok(1, "updateHITs");

