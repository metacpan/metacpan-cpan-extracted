package Net::Amazon::MechanicalTurk::Command::ParseAssignmentAnswer;
use strict;
use warnings;
use Carp;
use Net::Amazon::MechanicalTurk::QuestionFormAnswers;

our $VERSION = '1.00';

=head1 NAME

Net::Amazon::MechanicalTurk::Command::ParseAssignmentAnswer - Parses the answer from a completed assignment.

Returns an object of type Net::Amazon::MechanicalTurk::QuestionFormAnswers for an assignment
object.

=head1 SYNOPSIS

    my $assignments = $mturk->GetAssignmentsForHITAll( HITId => $hitId );
    while (my $assignment = $assignments->next) {
        my $answers = $mturk->parseAssignmentAnswer($assignment);
        $answers->eachAnswerValue(sub {
            my ($questionId, $answerText) = @_;
            print "%s = %s\n", $questionId, $answerText;
        });
    }

=cut 

sub parseAssignmentAnswer {
    my ($mturk, $assignment) = @_;
    
    if (!UNIVERSAL::isa($assignment, "HASH")) {
        Carp::croak("Invalid assignment object.");
    }
    if (!exists $assignment->{Answer}) {
        Carp::croak("Invalid assignment object.");
    }
    if (!exists $assignment->{AssignmentId}) {
        Carp::croak("Invalid assignment object.");
    }
    
    return Net::Amazon::MechanicalTurk::QuestionFormAnswers->new(
        answers      => $assignment->{Answer}[0],
        requesterUrl => $mturk->requesterUrl,
        assignmentId => $assignment->{AssignmentId}[0]
    );
}

return 1;
