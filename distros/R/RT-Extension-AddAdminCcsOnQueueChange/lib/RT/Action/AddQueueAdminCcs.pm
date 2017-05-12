=head1 NAME

  RT::Action::AddQueueAdminCcs

=head1 DESCRIPTION

AddQueuAdminCcs is a ScripAction which should be called for OnQueueChange
actions.  When a ticket is moved to a new queue, it adds the old queue's
AdminCcs as AdminCcs on the ticket.

Note that as currently implemented the action *only* works on queue change 
transactions, because it uses the transaction object instead of the ticket 
object and relies on the "old object" in the transaction being a queue.  Also, 
if the scrip is added to a single queue individually instead of all queues 
globally, it will only run when tickets are moved *into* the queue (although 
it will correctly add the old queue's AdminCcs to the ticket).  This is because 
RT (as of 3.4.2) apparently only runs the new queue's scrips when a ticket is 
moved.

The module simply gets the old queue from the transaction object and adds 
each principal (user or group) to the ticket's AdminCc watcher list 
iteratively.  RT's watcher-addition code takes care of preventing duplicate 
principals from being added to the ticket.

=head1 COPYRIGHT

This extension is Copyright (C) 2005 Best Practical Solutions, LLC.

It is freely redistributable under the terms of version 2 of the GNU GPL.

=cut


use warnings;
use strict;

package RT::Action::AddQueueAdminCcs;
use base qw/RT::Action/;

# add the queue's AdminCcs to the ticket's AdminCcs

sub Commit {
    my $self = shift;

    # get the AdminCc group of the ticket's old queue
    my $queue_adminccs;
    if ( $self->TransactionObj->Field eq 'Queue' ) {
        my $queue = new RT::Queue( $RT::SystemUser );
        $queue->Load( $self->TransactionObj->OldValue );
        $queue_adminccs = $queue->AdminCc;
    } 
    else {
        $RT::Logger->critical("This transaction doesn't involve a queue.  Are you sure you don't want the OnQueueChange condition?");
        return 0;   #false
    }

    # step through the members (users and groups) and add them to the ticket --
    # RT will take care of preventing duplicates.
    my $member_iterator = $queue_adminccs->MembersObj;
    while ( my $member = $member_iterator->Next ) {
        my $principal = $member->MemberObj;
        $self->TicketObj->AddWatcher(Type => 'AdminCc', PrincipalId => $principal->id);
    }

    return 1;
}

1;
