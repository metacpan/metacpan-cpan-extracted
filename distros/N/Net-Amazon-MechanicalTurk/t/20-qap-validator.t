#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN { push(@INC, "lib", "t"); }

sub validate {
    my ($validator, $xml, $expectedError) = @_;
    my %info;
    if (!$validator->validate($xml, \%info)) {
        ok($expectedError, "Expected XML error.");
        if ($expectedError) {
            ok(exists $info{message}, "XML has error message.");
            #printf STDERR "\n%s\nLocation: line %d column %d\n",
            #    $info{message},
            #    $info{line},
            #    $info{column};
        }
    }
    else {
        ok(!$expectedError, "XML is valid.");
    }
}

my $validator;
eval {
    require Net::Amazon::MechanicalTurk::QAPValidator;
    $validator = Net::Amazon::MechanicalTurk::QAPValidator->create;
};
if ($@) {
    # QAPValidator requires a heavier XML parser for validation.
    # Which is not needed for basic MTurk functionality.
    plan skip_all => "Can't load QAPValidator.";
}
else {
    plan tests => 5;
}

my $xml;

$xml = <<END_XML;
<?xml version="1.0" encoding="UTF-8"?>
<QuestionForm xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd">
  <Question>
    <QuestionIdentifier>1</QuestionIdentifier>
    <QuestionContent>
      <Text>Whats going on?</Text>
    </QuestionContent>
    <AnswerSpecification>
      <FreeTextAnswer/>
    </AnswerSpecification>
  </Question>
</QuestionForm>
END_XML
validate($validator, $xml, 0);


$xml = <<END_XML;
<?xml version="1.0" encoding="UTF-8"?>
<QuestionForm xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd">
  <Question>
    <QuestionIdentifier>&1</QuestionIdentifier>
    <QuestionContent>
      <Text>Whats going on?</Text>
    </QuestionContent>
    <AnswerSpecification>
      <FreeTextAnswer/>
    </AnswerSpecification>
  </Question>
</QuestionForm>
END_XML
validate($validator, $xml, 1);


$xml = <<END_XML;
<?xml version="1.0" encoding="UTF-8"?>
<QuestionForm xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd">
  <Question>
    <QuestionIdentifier>1</QuestionIdentifier>
    <QuestionContent>
      <Text>Whats going on?</Text>
    </QuestionContent>
    <AnswerSpecification>
      <FreeTextAnswer/>
    </AnswerSpecification>
  </Question>
  <foo/>
</QuestionForm>
END_XML
validate($validator, $xml, 1);
