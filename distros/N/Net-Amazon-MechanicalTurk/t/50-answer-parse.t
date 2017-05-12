#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
BEGIN { push(@INC, "lib", "t"); }
use Net::Amazon::MechanicalTurk::QuestionFormAnswers;

my $xml = <<END_XML;
<?xml version="1.0" encoding="UTF-8"?>
<QuestionFormAnswers xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionFormAnswers.xsd">
    <Answer>
        <QuestionIdentifier>q1</QuestionIdentifier>
        <SelectionIdentifier>q1-si-1</SelectionIdentifier>
    </Answer>
    <Answer>
        <QuestionIdentifier>q2</QuestionIdentifier>
        <SelectionIdentifier>q2-si-1</SelectionIdentifier>
        <SelectionIdentifier>q2-si-2</SelectionIdentifier>
    </Answer>
    <Answer>
        <QuestionIdentifier>q3</QuestionIdentifier>
        <SelectionIdentifier>q3-si-1</SelectionIdentifier>
		<OtherSelectionText>q3-ost</OtherSelectionText>
    </Answer>
    <Answer>
        <QuestionIdentifier>q4</QuestionIdentifier>
		<OtherSelectionText>q4-ost</OtherSelectionText>
    </Answer>
    <Answer>
        <QuestionIdentifier>q4</QuestionIdentifier>
        <FreeText>Hey there how are you?</FreeText>
    </Answer>
    <Answer>
        <QuestionIdentifier>q6</QuestionIdentifier>
        <UploadedFileSizeInBytes>20</UploadedFileSizeInBytes>
        <UploadedFileKey>q6-upkey</UploadedFileKey>
    </Answer>
</QuestionFormAnswers>
END_XML

my $answers = Net::Amazon::MechanicalTurk::QuestionFormAnswers->new(
    answers      => $xml,
    requesterUrl => "http://someurl",
    assignmentId => 'FAKEASNID'
);

my $hash = $answers->getAnswerValues();

is_deeply($hash, {
        q1 => 'q1-si-1',
        q2 => 'q2-si-1|q2-si-2',
        q3 => 'q3-si-1|q3-ost',
        q4 => 'Hey there how are you?',
        q6 => 'http://someurl/mturk/downloadAnswer?assignmentId=FAKEASNID&questionId=q6',
    }, "QuestionFormAnswers");




