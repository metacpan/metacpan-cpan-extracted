use v5.36;

package RT::Action::OwnerAwayReassign;
use base qw(RT::Action);

=head1 NAME

RT::Action::OwnerAwayReassign

=head1 DESCRIPTION

Scrip action, meant to be paired with L<RT::Condition::OwnerAway>. Reassigns
the ticket's owner to Nobody and leaves an internal comment explaining that
the previous owner is away. Runs the actual mutation as C<RT-E<gt>SystemUser>
so it succeeds regardless of the replying user's rights, and uses
C<Comment> (not C<Correspond>) so the note stays internal.

The comment is added only after C<SetOwner> has succeeded, so by the time it
creates its own transaction the ticket is owned by Nobody and
L<RT::Condition::OwnerAway> no longer matches. That ordering is what keeps
the scrip from looping now that comments can trigger it too, so don't
reorder these two steps.

=cut

sub Prepare ($self) {
    return 1;
}

sub Commit ($self) {
    my $former_owner      = $self->TicketObj->OwnerObj;
    my $former_owner_name = $former_owner->Name;

    my $ticket = RT::Ticket->new( RT->SystemUser );
    my ( $ok, $msg ) = $ticket->Load( $self->TicketObj->Id );
    unless ($ok) {
        RT->Logger->error( "AwayMode: could not reload ticket "
              . $self->TicketObj->Id
              . ": $msg" );
        return 0;
    }

    my ( $set_ok, $set_msg ) = $ticket->SetOwner( RT->Nobody->Id, 'Set' );
    unless ($set_ok) {
        RT->Logger->error( "AwayMode: could not reassign ticket "
              . $ticket->Id
              . " to Nobody: $set_msg" );
        return 0;
    }

    my $prefs   = $former_owner->Preferences( 'AwayMode', {} );
    my $comment = "This ticket's owner, $former_owner_name, is away";
    $comment .= " until $prefs->{'EndDate'}" if $prefs->{'EndDate'};
    $comment .= ". Reassigning to Nobody so the team can pick it up.";

    my ( $comment_ok, $comment_msg ) = $ticket->Comment( Content => $comment );
    unless ($comment_ok) {
        RT->Logger->error( "AwayMode: could not add comment to ticket "
              . $ticket->Id
              . ": $comment_msg" );
    }

    return 1;
}

1;
