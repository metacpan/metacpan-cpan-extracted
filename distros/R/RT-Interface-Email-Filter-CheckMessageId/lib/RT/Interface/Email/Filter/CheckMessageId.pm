package RT::Interface::Email::Filter::CheckMessageId;

our $VERSION = '0.2';

use warnings;
use strict;

use RT::Interface::Email qw();

=head1 NAME

RT::Interface::Email::Filter::CheckMessageId - Find related ticket from references mail header

=head1 DESCRIPTION

This extension check if received mail correspond to an already existing ticket
according C<In-Reply-To> and C<References> header tag.

If a ticket (and only one) is found the mail subject is altered to include the
C<[... #n]> mark, so RT will push the mail as mail comment instead creating a
new ticket.

This is usefull with this scenario:
C<Requestor> send a mail to C<RT system> and a C<Friend>. The C<Friend> think he
can help, so reply to all without the subject properly tagged, then RT create a
new ticket.

With This extension, RT will find the C<In-Reply-To> header tag match with the
ticket's attachement and then the C<Friend>'s mail will be added as comment.

=head1 CONFIGURATION

=head2 $ChkMsgIdNoIfStatus

If set ticket in state listed are ignore letting a new
bug to be open.

C<Initial> keywords will match all initial state (C<new>).

C<Active> keywords will match all inactive state (C<open>).

C<Inactive> keywords will match all inactive state (C<rejected>, C<resolved>).

=head1 PERFORMANCE

This plugin search messages Id in column 'messageid' of the table 'attachments'.
It is strongly recommanded to create an index to speed-up the search in this
table.

Connect to the database:

    CREATE INDEX messageid_idx ON attachments (messageid);

=cut

=head1 FUNCTIONS

=head2 ApplyBeforeDecode

Modify header subject to include C<[... #n]> ticket reference.

=cut

sub _Find_Ticket_from_MsgID {
    my %args = (
        MsgID => [],
        CurrentUser => undef,
        @_
    );
    my @NoIfStatus = split(/[\s,]+/, RT::Config->Get('ChkMsgIdNoIfStatus') || '');

    my %attachmentids;
    foreach my $msgid (@{ $args{MsgID} }) {
        my $attachments = RT::Attachments->new( $RT::SystemUser );
        $attachments->Limit(
            FIELD => 'MessageId',
            VALUE => $msgid,
        );

        while (my $attachment = $attachments->Next) {
            my $trans = $attachment->TransactionObj or next;
            $trans->ObjectType eq 'RT::Ticket' or next;
            my $objid = $trans->ObjectId or next;
            my $ticketid = $trans->ObjectId;

            if (@NoIfStatus) {
            my $TicketObj = RT::Ticket->new( $RT::SystemUser );
            $TicketObj->Load( $ticketid );
            
            if (grep { $_ eq $TicketObj->Status } @NoIfStatus) {
                next;
            }
            if ((grep { $_ eq 'Initial' } @NoIfStatus) &&
                $TicketObj->QueueObj
                    ->Lifecycle->IsInitial($TicketObj->Status)) {
                next; 
            }
            if ((grep { $_ eq 'Active' } @NoIfStatus) &&
                $TicketObj->QueueObj
                    ->Lifecycle->IsActive($TicketObj->Status)) {
                next; 
            }
            if ((grep { $_ eq 'Inactive' } @NoIfStatus) &&
                $TicketObj->QueueObj
                    ->Lifecycle->IsInactive($TicketObj->Status)) {
                next;
            }
            }
            
            $attachmentids{$ticketid} = 1;
        }
    }
    my ($ticketid, @others) = keys %attachmentids;
    if (@others) {
        # Error, multiple ticket
        return;
    } else {
        return($ticketid);
    }
}

sub _Redefine_Subjet {
    my %args = (
        Message       => undef,
        Ticket        => undef,
        @_
    );

    $args{'Message'}->head->replace('Subject',
        sprintf('[%s #%d] %s' . "\n",
            RT->Config->Get('rtname') || '',
            $args{Ticket},
            $args{'Message'}->head->get('Subject'),
        )
    );

}

sub ApplyBeforeDecode {
    my %args = (
        Message       => undef,
        RawMessageRef => undef,
        CurrentUser   => undef,
        AuthLevel     => undef,
        Action        => undef,
        Ticket        => undef,
        Queue         => undef,
        @_
    );

    # If we have allready a ticket or we can find ticket number in subject
    # ignore mail header:
    if (RT::Interface::Email->can('ExtractTicketId')) {
        if (RT::Interface::Email::ExtractTicketId($args{'Message'})) {
            return ( 0 );
        }
    } else {
        # RT 4.0.6 and earlier does not have ExtractTicketId
        my $subject = $args{'Message'}->head->get('Subject') || '';
        chomp $subject;
        if (RT::Interface::Email::ParseTicketId($subject)) {
            return ( 0 );
        }
    }

    # We have 'In-Reply-To' header:
    if (my $inreplyto = $args{'Message'}->head->get('In-Reply-To')) {
    chomp($inreplyto);
    $inreplyto =~ s/^<//; $inreplyto =~ s/>$//;
    $RT::Logger->debug("Found In-Reply-To: $inreplyto");

    if (my $ticketid = _Find_Ticket_from_MsgID(
        CurrentUser => $args{'CurrentUser'},
        MsgID => [ $inreplyto ],
    )) {
        $RT::Logger->debug("according In-Reply-To: ticket is $ticketid");
        _Redefine_Subjet(
            Ticket => $ticketid,
            Message => $args{'Message'},
        );
	return( 0 );
    }
    }

    # We have 'References' header
    my $references = $args{'Message'}->head->get('References') || '';
    chomp($references);
    if (my @msgids = map { s/^<//; s/>$//; $_ } split(/\s+/, $references)) {
    $RT::Logger->debug("Found References header");
    if (my $ticketid = _Find_Ticket_from_MsgID(
        CurrentUser => $args{'CurrentUser'},
        MsgID => \@msgids,
    )) {
        $RT::Logger->debug("according References: ticket is $ticketid");
        _Redefine_Subjet(
            Ticket => $ticketid,
            Message => $args{'Message'},
        );
    }
    }

    return ( 0 );
}

=head2 GetCurrentUser

Return current user.

Does nothing, this method is here to allow the plugin to be detected

=cut

sub GetCurrentUser {
    my %args = (
        Message       => undef,
        RawMessageRef => undef,
        CurrentUser   => undef,
        AuthLevel     => undef,
        Action        => undef,
        Ticket        => undef,
        Queue         => undef,
        @_
    );
    return ( $args{'CurrentUser'}, $args{'AuthLevel'} );
}

=head1 AUTHOR

  Olivier Thauvin <nanardon@nanardon.zarb.org>

=head1 CONTRIBUTORS

  Asa Gage <agage at nextjump.com>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Olivier Thauvin

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

1;
