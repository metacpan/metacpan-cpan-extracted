use strict;
use warnings;

package RT::Action::NotifyAtTicketLevel;
use base qw(RT::Action::Notify);

sub SetRecipients {
    my $self    = shift;
    my $ticket  = $self->TicketObj;
    my $arg     = $self->Argument;

    # Standard Notify behaviour
    $self->SUPER::SetRecipients(@_);

    my (@Cc, @Bcc);

    # Support additional watcher args for ticket-level.  These are only useful
    # if you don't specify Cc or AdminCc also, obviously.
    if ($arg =~ /\bTicketCc\b/) {
        push @Cc, $ticket->Cc->MemberEmailAddresses;
    }
    if ($arg =~ /\bTicketAdminCc\b/) {
        push @Bcc, $ticket->AdminCc->MemberEmailAddresses;
    }

    # NotifyActor logic cribbed from the superclass
    my $creatorObj = $self->TransactionObj->CreatorObj;
    my $creator = $creatorObj->EmailAddress() || '';
    my $TransactionCurrentUser = RT::CurrentUser->new;
    $TransactionCurrentUser->LoadByName($creatorObj->Name);
    unless (RT->Config->Get('NotifyActor',$TransactionCurrentUser)) {
        @Cc  = grep { lc $_ ne lc $creator } @Cc;
        @Bcc = grep { lc $_ ne lc $creator } @Bcc;
    }

    # Add to internal recipient fields used by RT::Action::SendEmail
    push @{ $self->{'Cc'} }, @Cc;
    push @{ $self->{'Bcc'} }, @Bcc;

    return 1;
}

=head1 NAME

RT::Action::NotifyAtTicketLevel

=head1 DESCRIPTION

A subclass of L<RT::Action::Notify> which supports the C<TicketCc> and
C<TicketAdminCc> roles in the comma-separated value of
L<RT::ScripAction/Argument>, in addition to the normal role names.  C<Argument>
is set in the database via an
L<initialdata|https://bestpractical.com/rt/docs/latest/initialdata.html> file
which creates the L<RT::ScripAction>.

The C<TicketCc> and C<TicketAdminCc> will skip adding any queue watchers to the
recipients list.

=cut

1;
