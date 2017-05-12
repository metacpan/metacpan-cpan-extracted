package Net::Amazon::MechanicalTurk::Command::DeleteHIT;
use strict;
use warnings;
use Carp;

our $VERSION = '1.00';

=head1 NAME

Net::Amazon::MechanicalTurk::Command::DeleteHIT - Attempts to delete a HIT.

=head1 SYNOPSIS

    # Deletes a hit by HITId and approves any submitted assignments for the hit.
    $mturk->deleteHIT($hitId, 1);

    # Tries to delete a HIT, but will fail if there are any submitted assignments.
    $mturk->deleteHIT($hitId, 0);

=head1 C<addRetry>

addRetry

Deletes a HIT from MechanicalTurk.  In order to delete the HIT, this fuction
will first try disposing the hit.  If the hit can not be disposed, it will 
attempt to force expire the hit and then dispose it.  If that operation fails
and the autoApprove flag is on, then submitted assignments will be approved
and another disposal attempt will be made.

Even, if this method fails, the HIT may have been changed.  It could have
been force expired, but still failed disposal.  Assignments may also have
been approved, even though the last disposal attempt failed.

=cut 

sub deleteHIT {
    my ($mturk, $hitId, $autoApprove) = @_;
    
    eval { $mturk->DisposeHIT( HITId => $hitId ); };
    return unless $@;
    
    my $hit = $mturk->GetHIT( HITId => $hitId );
    my $status = $hit->{HITStatus}[0];
    
    return if ($status eq "Disposed");
    
    # Try to expire the HIT and then dispose it
    eval { $mturk->ForceExpireHIT( HITId => $hitId ); };
    eval { $mturk->DisposeHIT( HITId => $hitId ); };
    return unless $@;
    
    # Approve all submitted hits
    if ($autoApprove) {
        my $assignments = $mturk->GetAssignmentsForHITAll(
            HITId => $hitId,
            AssignmentStatus => 'Submitted'
        );
        while (my $assignment = $assignments->next) {
            my $assignmentId = $assignment->{AssignmentId}[0];
            $mturk->ApproveAssignment( AssignmentId => $assignmentId );
        }
    }
    else {
        Carp::croak("Could not delete hit $hitId with autoApproval off.");
    }
    
    eval { $mturk->DisposeHIT( HITId => $hitId ); };
    return unless $@;
    
    Carp::croak("Could not delete hit, it may be in the process of being worked on.\n\n" . $@);
}

return 1;
