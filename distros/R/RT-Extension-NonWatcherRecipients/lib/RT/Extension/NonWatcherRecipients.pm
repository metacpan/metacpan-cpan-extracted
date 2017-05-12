use strict;
use warnings;
package RT::Extension::NonWatcherRecipients;

our $VERSION = '1.01';

=head1 NAME

RT-Extension-NonWatcherRecipients - Note when non-watchers received an
email which RT redistributed to watchers

=head1 DESCRIPTION

Sometimes email addresses will be added to a thread attached to an RT ticket
because someone wants someone else to know what's going on. However, if that
person isn't added as a Watcher on the RT ticket, they'll likely miss
subsequent correspondence on the thread as RT doesn't know about them.

L<RT::Extension::NonWatcherRecipients> looks for email addresses on
correspondence that RT doesn't know about and posts a message like this
so you know someone may need to be added:

    ------------------------------------------------------------------------
       From: "A User" <a-user@example.com>

    The following people received a copy of this email but are not on the ticket.
    You may want to add them before replying:
    https://YourRT.com/Ticket/ModifyPeople.html?id=12345

       Cc: "Non Watcher" <non-watcher@example.com>
    ------------------------------------------------------------------------

If you want the person to see correspondence, you can click the link and add
them. If not, you can just ignore the message.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::NonWatcherRecipients');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::NonWatcherRecipients));

or add C<RT::Extension::NonWatcherRecipients> to your existing C<@Plugins> line.

=item Restart your webserver

=back

=head1 USAGE

If you run the C<make initdb> step, a new global template called
C<NonWatcherRecipients Admin Correspondence> is installed on your system.
You can then select this template for any scrips that use the
standard C<Admin Correspondence> template. We recommend the
C<Admin Correspondence> template because you'll need RT privileges
to add the user to the ticket.

You can also add this to existing templates by adding the following
to any template:

    { RT::Extension::NonWatcherRecipients->FindRecipients(
        Transaction => $Transaction, Ticket => $Ticket ) }

As described below, this method returns a message which is then inserted into
your template.  Look at the installed template for an example.  You may also
call the method and use the returned string however you'd like.

=head1 METHODS

=head2 FindRecipients

Search headers for recipients not included as watchers on the ticket
and return a message to insert in the outgoing email to notify
participants.

Takes: (Transaction => $Transaction, Ticket => $Ticket)
These are the objects provided in the RT template.

Returns: a message to insert in a template

=cut

sub FindRecipients {
    my $self = shift;
    my %args = @_;
    my $Transaction = $args{Transaction};
    my $Ticket = $args{Ticket};
    my $recipients; # List of recipients
    my $message = ""; # Message for template

    unless ( $Transaction->Id and $Ticket->Id ){
        RT::Logger->error("Transaction and Ticket objects are required. "
                          . "Received Transaction Id: " . $Transaction->Id
                          . " and Ticket Id: " . $Ticket->Id);
        return "";
    }

    return "" unless my $att = $Transaction->Attachments->First;

    my %addr = %{ $att->Addresses };
    my $creator = $Transaction->CreatorObj->RealName || '';

    # Show any extra recipients
    for my $hdr (qw(From To Cc RT-Send-Cc RT-Send-Bcc)) {
        my @new = grep { not $self->IsWatcher($_->address, $Ticket) } @{$addr{$hdr} || []};
        $recipients .= "   $hdr: " . $self->Format(\@new) . "\n"
            if @new;
    }

    if ($recipients) {
        $message = "The following people received a copy of this email "
                 . "but are not on the ticket. You may want to add them "
                 . "before replying: ${RT::WebURL}Ticket/ModifyPeople.html?id="
                 . $Ticket->id . "\n\n$recipients";
    }

    # Show From if there's a different phrase; this catches name changes and "via RT"
    my @from = grep { ($_->phrase||'') ne $creator } @{$addr{From} || []};
    $message = "   From: " . $self->Format(\@from) . ($message ? "\n\n$message" : "\n")
        if @from;

    if ($message) {
        my $sep  = "-" x 72;
        $message = "$sep\n$message$sep\n";
    }

    return $message;
}

sub IsWatcher {
    my $self = shift;
    my $email = shift;
    my $Ticket = shift;

    # Look up the specified user.
    my $user = RT::User->new(RT->SystemUser);
    $user->LoadByEmail($email);
    return unless $user->Id;
    for (qw(Requestor Cc AdminCc Owner)) {
        return 1 if $Ticket->IsWatcher( Type => $_, PrincipalId => $user->PrincipalId );
    }
    for (qw(Cc AdminCc)) {
        return 1 if $Ticket->QueueObj->IsWatcher( Type => $_, PrincipalId => $user->PrincipalId );
    }
    return 0;
}

sub Format {
    my $self = shift;
    return join ", ", map { $_->format } @{$_[0] || []};
}

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-NonWatcherRecipients@rt.cpan.org|mailto:bug-RT-Extension-NonWatcherRecipients@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-NonWatcherRecipients>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2013-2016 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
