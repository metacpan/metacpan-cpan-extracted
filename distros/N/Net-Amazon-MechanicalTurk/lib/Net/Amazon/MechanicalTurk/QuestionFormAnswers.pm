package Net::Amazon::MechanicalTurk::QuestionFormAnswers;
use strict;
use warnings;
use Net::Amazon::MechanicalTurk::DataStructure;
use Net::Amazon::MechanicalTurk::XMLParser;
use URI::Escape;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::BaseObject };

Net::Amazon::MechanicalTurk::QuestionFormAnswers->attributes(qw{
    answers
    requesterUrl
    assignmentId
    answerSeparator
});

sub init {
    my $self = shift;
    $self->setAttributes(@_);
    $self->setAttributesIfNotDefined(
        answerSeparator => '|'
    );
    $self->assertRequiredAttributes(qw{
        answers
        requesterUrl
        assignmentId
    });
    my $answers = $self->answers;
    if (UNIVERSAL::isa($answers, "Net::Amazon::MechanicalTurk::DataStructure")) {
        $self->answers($answers);
    }
    else {
        my $rootElement;
        ($answers, $rootElement) = Net::Amazon::MechanicalTurk::XMLParser->new->parse($answers);
        $self->answers($answers);
    }
}

sub getAnswer {
    my ($self, $questionId) = @_;
    foreach my $answer (@{$self->answers->{Answer}}) {
        if ($answer->{QuestionIdentifier}[0] eq $questionId) {
            return $answer;
        }
    }
    return undef;
}

sub getAnswerValues {
    my $self = shift;
    my $answers = {};
    $self->eachAnswerValue(sub {
        my ($questionId, $answerText) = @_;
        $answers->{$questionId} = $answerText;
    });
    return $answers;
}

sub eachAnswerValue {
    my ($self, $code) = @_;
    foreach my $answer (@{$self->answers->{Answer}}) {
        my $questionId = $answer->{QuestionIdentifier}[0];
        my $answerText = $self->getAnswerValue($answer);
        $code->($questionId, $answerText);
    }
}

sub getAnswerValue {
    my ($self, $answer) = @_;
    my $value = '';
    if (exists $answer->{FreeText}) {
        $value = $answer->{FreeText}[0];
    }
    elsif (exists $answer->{UploadedFileKey}) {
        $value = $self->getDownloadUrl($answer->{QuestionIdentifier}[0]);
    }
    else {
        my $count = 0;
        if (exists $answer->{SelectionIdentifier}) {
            foreach my $sid (@{$answer->{SelectionIdentifier}}) {
                if ($count++ > 0) {
                    $value .= $self->answerSeparator;
                }
                $value .= $sid;
            }
        }
        if (exists $answer->{OtherSelectionText}) {
            foreach my $sid (@{$answer->{OtherSelectionText}}) {
                if ($count++ > 0) {
                    $value .= $self->answerSeparator;
                }
                $value .= $sid;
            }
        }
    }
    return $value;
}

sub getDownloadUrl {
    my ($self, $questionId) = @_;
    return sprintf "%s/mturk/downloadAnswer?assignmentId=%s&questionId=%s",
        $self->requesterUrl,
        uri_escape($self->assignmentId),
        uri_escape($questionId);
}

sub toString {
    my $self = shift;
    return $self->answers->toString;
}

return 1;
