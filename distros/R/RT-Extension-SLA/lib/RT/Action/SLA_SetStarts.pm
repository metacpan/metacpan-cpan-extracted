use strict;
use warnings;

package RT::Action::SLA_SetStarts;

use base qw(RT::Action::SLA);

=head1 NAME

RT::Action::SLA_SetStarts - set starts date field of a ticket according to SLA

=head1 DESCRIPTION

Look up the SLA of the ticket and set the Starts date accordingly. Nothing happens
if the ticket has no SLA defined.

Note that this action doesn't check if Starts field is set already, so you can
use it to set the field in a force mode or can protect field using a condition
that checks value of Starts.

=cut

sub Prepare { return 1 }

sub Commit {
    my $self = shift;

    my $ticket = $self->TicketObj;

    my $level = $ticket->FirstCustomFieldValue('SLA');
    unless ( $level ) {
        $RT::Logger->debug('Ticket #'. $ticket->id .' has no service level defined, skip setting Starts');
        return 1;
    }

    my $starts = $self->Starts(
        Ticket => $ticket,
        Level => $level,
        Time => $ticket->CreatedObj->Unix,
    );

    return $self->SetDateField( Starts => $starts );
}

1;
