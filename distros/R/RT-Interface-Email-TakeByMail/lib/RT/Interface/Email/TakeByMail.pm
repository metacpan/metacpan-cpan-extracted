package RT::Interface::Email::TakeByMail;

our $VERSION = '1.3';

=head1 NAME

    RT::Interface::Email::TakeByMail - Change ownership via email response.

=head1 SYNOPSIS

    AdminCcs can reply 'Mine' or 'Take' via email and they will be assigned the
    ticket.

=head1 INSTALL

    1. etc/RT_SiteConfig.pm

        # note: TakeByMail must precede TakeAction if TakeAction is installed.
        Set(@MailPlugins, qw/Auth::MailFrom  RT::Extension::TakeByMail/);
        Set(@Plugins,     qw/RT::Interface::Email::TakeByMail/         );

    2. Setup watchers for a queue as AdminCcs.

    3. Web config - add "as Comment" to global scrip "On Create notify AdminCcs"

        - Description => "On Create Notify AdminCcs as Comment".
        - Action      => "Notify AdminCcs as Comment"
        - Template    => "Global: Admin Comment"

=head1 AUTHOR

    Alister West - http://alisterwest.com/

=head1 LICENCE AND COPYRIGHT

    Copyright 2013, Alister West

    This module is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself. See http://dev.perl.org/licenses/.

=cut

use 5.008;
use warnings;
use strict;

use RT::Interface::Email qw(ParseCcAddressesFromHead);

=head2 GetCurrentUser

    Returns a tupple of (CurrentUser, $AuthStat).
    (see RT::Interface::Email::GetAuthenticationLevel for docs on $AuthStat values)

    Checks incoming mail for the first non-blank =~ /Take|Mine/.
    If so and $user is AdminCC it will SetOwner($user) and SetStatus($active).

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

    $RT::Logger->debug("TakeTicket");

    my @param = ( $args{'CurrentUser'}, $args{'AuthLevel'} );

    #
    # Check we have a valid request
    #
    unless ( $args{'CurrentUser'} && $args{'CurrentUser'}->Id ) {
        $RT::Logger->error(
            "Filter::TakeAction executed when CurrentUser (actor) is not authorized. "
            ."Most probably you want to add Auth::MailFrom plugin before "
            ."Filter::TakeAction in the \@MailPlugins config."
        );
        return @param;
    }

    # Make sure we have a ticket to Take
    return @param unless $args{'Action'} =~ /^(?:comment|correspond)$/i;
    return @param unless $args{'Ticket'}->id;

    # Load Ticket
    my $ticket = RT::Ticket->new( $args{'CurrentUser'} );
    $ticket->Load( $args{'Ticket'}->id );
    $RT::Logger->debug("TakeTicket [". $ticket->Id . "] Owner: ". $ticket->OwnerObj->Name);

    # Only take tickets belonging to Nobody so only the first response is actioned.
    return @param unless $ticket->OwnerObj->Name eq 'Nobody';

    # Get the Ticket's queue - not the queue passed into mailgate.
    my $queue = RT::Queue->new( $args{'CurrentUser'} );
    $queue = $ticket->QueueObj;

    # Ensure the ticket either exists or is heading to a target queue.
    return @param unless ($ticket->Id and $queue->Id);

    # Ensure the Responder is an admin
    my $is_admin = $queue->IsAdminCc( $args{CurrentUser}->UserObj->Id );
    $RT::Logger->debug("TakeTicket IsAdminCc: " . $is_admin ? 1 : 0);
    return @param unless $is_admin;


    #
    # Find the first line of the Emails content.
    # - We accept Mine or Take as the first word on the first non-blank line.
    #
    my @parts = $args{'Message'}->parts_DFS;
    my $take = '';
    foreach my $part (@parts) {
        my $body = $part->bodyhandle or next;
        # $RT::Logger->debug("msg: ".  $body->as_string );
        if ( $body->as_string =~ /^\s*(take|mine)\b/mi ) {
            $take = $1;
            last;
        }
    }
    return @param unless $take;


    #
    # Update Ticket: Owner = Admin-Commentter, Status = Active(open).
    #
    # - Sets ticket to an Active status (if not already).
    #   Similar to RT::Action::AutoOpen but without a transaction.
    #
    my ($ok, $msg) = $ticket->SetOwner( $args{'CurrentUser'}->UserObj->Id );
    if ($ok) {
        $RT::Logger->debug( $args{'CurrentUser'}->UserObj->Name . " has taken the ticket!" );

        my $next    = $ticket->FirstActiveStatus;
        my $is_new  = $ticket->QueueObj->Lifecycle->IsInitial($ticket->Status);
        if ($is_new and $next) {
            my ($ok, $msg) = $ticket->SetStatus( $next );

            # raise privileges as this is an admin user
            if ($ok) {
                return ($args{CurrentUser}, 2) if $ok;
            } else {
                $RT::Logger->error( "TakeTicket AutoOpen failed: $msg");
            }
        }

    }
    else {
        $RT::Logger->error( "TakeTicket failed: $msg" );
        return @param;
    }

    return @param;
}


1;
