use strict;
use warnings;
package RT::Action::AutoAddWatchers;
use base 'RT::Action';

our $VERSION = '0.02';

use List::MoreUtils qw< part >;

=head1 NAME

RT-Action-AutoAddWatchers - A more powerful C<$ParseNewMessageForTicketCcs>

=head1 DESCRIPTION

Automatically adds new watchers from the current transaction to the ticket,
while trying to do so intelligently.  The basic rules:

=over

=item * Addresses are extracted from the To, Cc, and From headers.

=item * Any address matching a configured address for RT is discarded.

=item * Any address which is already a ticket watcher is discarded.

=item * If the address matches a privileged user, the user is added as a ticket AdminCc.

=item * Otherwise, the address is added as a ticket Cc.

=back

=cut

sub Prepare {
    my $self = shift;
    my $Ticket = $self->TicketObj;
    my $Transaction = $self->TransactionObj;
    return unless $Ticket and $Transaction;

    # Extract addresses
    # Filter for IsRTAddress
    # Filter for existing watchers
    # Part privileged users into AdminCc and others into Cc
    return unless my $msg = $Transaction->Attachments->First;

    my %addr = %{ $msg->Addresses };

    ($self->{AdminCcs}, $self->{Ccs}) =
        part { $self->IsPrivileged($_->address) ? 0 : 1 }
        grep { not $self->IsTicketWatcher($_->address) }
        grep { not RT::EmailParser->IsRTAddress($_->address) }
         map { @{ $addr{$_} || [] } }
           qw( From To Cc );

    return 1;
}

sub Commit {
    my $self = shift;
    my $AdminCcs = $self->{AdminCcs} || [];
    my $Ccs = $self->{Ccs} || [];

    return 1 unless @$AdminCcs or @$Ccs;

    # RT will take care of preventing duplicates.
    for ([ AdminCc => $AdminCcs ], [ Cc => $Ccs ]) {
        for my $addr (@{$_->[1]}) {
            my ($ok, $msg) = $self->TicketObj->AddWatcher(
                Type  => $_->[0],
                Email => $addr->address,
            );
            unless ($ok) {
                RT->Logger->error( sprintf
                    "Unable to add <%s> as %s to ticket #%d: %s",
                    $addr->address, $_->[0], $self->TicketObj->id, $msg
                );
            }
        }
    }

    return 1;
}

sub IsTicketWatcher {
    my $self = shift;
    my $email = shift;
    my $Ticket = $self->TicketObj;

    my $user = RT::User->new(RT->SystemUser);
    $user->LoadByEmail($email);
    return unless $user->Id;
    for (qw(Requestor Cc AdminCc Owner)) {
        return 1 if $Ticket->IsWatcher( Type => $_, PrincipalId => $user->PrincipalId );
    }
    return 0;
}

sub IsPrivileged {
    my $self = shift;
    my $email = shift;

    my $user = RT::User->new(RT->SystemUser);
    $user->LoadByEmail($email);
    return unless $user->Id;
    return $user->Privileged;
}

=pod

Notably, this does B<not> skip addresses which are already queue watchers.  The
intent is to ensure that explicitly named people remain explicit on the ticket
but don't receive duplicate mail.  This is the reason for the distinction
between ticket Cc/AdminCc, under the assumption that your queue watchers are
AdminCcs.  It also pairs nicely with a notification setup using
L<RT::Extension::NotifyBasedOnOwnership> and enables queue watchers to be
looped into specific tickets via the initial email.

The default installation does B<not> create a scrip for you.  You must do that
for yourself using the new I<Automatically add ticket watchers from new
addresses> action.  A suggested scrip is:

    Condition: On Create
    Action: Automatically add ticket watchers from new addresses
    Template: Blank
    Stage: Normal

I strongly suggest only running this action I<On Create> instead of on all
correspondences (matching the behaviour of C<$ParseNewMessageForTicketCcs>)
so that watchers may not add themselves simply by replying to a ticket.

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

Add this line:

    Plugin("RT::Action::AutoAddWatchers");

or add C<RT::Action::AutoAddWatchers> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=item Create a scrip (or scrips) as appropriate for your installation using the new action.

=back

=head1 AUTHOR

Thomas Sibley <trsibley@uw.edu>

=head1 BUGS

All bugs should be reported via email to
L<bug-RT-Action-AutoAddWatchers@rt.cpan.org|mailto:bug-RT-Action-AutoAddWatchers@rt.cpan.org>
or via the web at
L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Action-AutoAddWatchers>.

=head1 SEE ALSO

L<RT::Extension::NonWatcherRecipients>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Thomas Sibley

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
