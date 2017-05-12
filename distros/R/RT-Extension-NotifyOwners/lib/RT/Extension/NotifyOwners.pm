use 5.8.0;
use strict;
use warnings;

package RT::Extension::NotifyOwners;

our $VERSION = '0.02';

=head1 NAME

RT::Extension::NotifyOwners

The NotifyOwners extension adds the following scrip actions:

    Notify Last Owner       - Previous owner
    Notify Potential Owners - Users with OwnTicket right
    Notify Previous Owners  - All previous owners

=head1 DESCRIPTION

RT action module that allow you to notify potential owners of a ticket.

=head1 INSTALL

=over 4

=item perl Makefile.PL

=item make

=item make install

=item rt-setup-database --action insert --datafile etc/initialdata

=back

=cut

use base qw(RT::Action::Notify);
require RT::Users;

=head2 LastOwner

Returns the email address of the last owner of a ticket.

=cut

sub LastOwner {
    my $self = shift;

    # Fetch the ticket object
    my $ticket = $self->TicketObj;

    my $To = "";

    # Get all the Owner change transactions for this ticket
    my $transactions = $ticket->Transactions;
    $transactions->Limit( FIELD => 'Field', VALUE => 'Owner' );

    # Check for greater than zero trasactions & fetch the user
    if($transactions->Count > 0) {
        my $transaction = $transactions->Last;
        
        # Get the user details from the database
        my $User = RT::User->new($RT::SystemUser);
        $User->Load($transaction->OldValue);
        $To = $User->EmailAddress;
    }

    return ($To);
}

=head2 PotentialOwners

Returns the email addresses of all users with the OwnTicket right
for the given ticket.

=cut

sub PotentialOwners {
    my $self = shift;

    # Fetch the ticket object
    my $ticket = $self->TicketObj;

    # Recipient list, use a hash for automatic removal of dupes
    my $To = {};

    # Find out who can own tickets in this queue.
    my $Users = RT::Users->new($RT::SystemUser);
    $Users->WhoHaveRight(Right => 'OwnTicket',
                         Object => $ticket->QueueObj,
                         IncludeSystemRights => 1,
                         IncludeSuperusers => 0);

    # Iterate over the users getting the email address
    while (my $User = $Users->Next()) {
        $To->{$User->EmailAddress} = 1;
    }

    return keys(%$To);
}

=head2 PrevOwners

Returns the email addresses of all previous owners for the ticket.

=cut

sub PrevOwners {
    my $self = shift;

    # Fetch the ticket object
    my $ticket = $self->TicketObj;

    # Recipient list, use a hash for automatic removal of dupes
    my $To = {};

    # Get all the Owner change transactions for this ticket
    my $transactions = $ticket->Transactions;
    $transactions->Limit( FIELD => 'Field', VALUE => 'Owner' );

    # Iterate the transactions
    while ( my $transaction = $transactions->Next ) {
        
        # Get the user details from the database
        my $User = RT::User->new($RT::SystemUser);
        $User->Load($transaction->OldValue);

        $To->{$User->EmailAddress} = 1;
    }

    return keys(%$To);
}

=head1 AUTHOR

    Ian Norton E<lt>i.d.norton@gmail.comE<gt>

    Based on RT::Action::NotifyGroup by Ruslan U. Zakirov

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with perl distribution.

=head1 SEE ALSO

RT::Action::Notify

=cut

1;
