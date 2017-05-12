use strict;
use warnings;
package RT::Action::AssignUnownedToActor;

our $VERSION = '1.01';

use base qw(RT::Action);

sub Prepare {
    my $self = shift;

    # Only unowned tickets
    return 0 if $self->TicketObj->OwnerObj->id != RT->Nobody->id;

    # when the actor isn't RT_System
    my $actor = $self->TransactionObj->CreatorObj;
    return 0 if $actor->id == RT->SystemUser->id;

    # and the actor isn't a requestor
    return 0 if $self->TicketObj->Requestors->HasMember( $actor->id );

    # and the actor can own tickets
    return 0 unless $actor->PrincipalObj->HasRight(
        Object => $self->TicketObj,
        Right  => 'OwnTicket',
    );

    $self->{'set_owner_to'} = $actor->id;
    return 1;
}

sub Commit {
    my $self = shift;
    my $owner = $self->{'set_owner_to'};

    RT->Logger->debug("Setting owner to $owner");
    my ($ok, $msg) = $self->TicketObj->SetOwner( $owner );

    unless ($ok) {
        RT->Logger->error("Couldn't set owner to $owner: $msg");
        return 0;
    }
    return 1;
}

=head1 NAME

RT-Action-AssignUnownedToActor - Assigns unowned tickets to the transaction actor

=head1 DESCRIPTION

Assigns tickets to the actor of the transaction that triggered the
scrip, if all the conditions below are met:

=over 4

=item The ticket is owned by Nobody

=item The actor isn't RT_System

=item The actor isn't a requestor on the ticket

=item The actor has the right to own the ticket

=back

Note that this means the requestor will never be assigned as the owner
by this action.

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

    Plugin('RT::Action::AssignUnownedToActor');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Action::AssignUnownedToActor));

or add C<RT::Action::AssignUnownedToActor> to your existing C<@Plugins> line.

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Action-AssignUnownedToActor@rt.cpan.org|mailto:bug-RT-Action-AssignUnownedToActor@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Action-AssignUnownedToActor>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2011-2014 by Best Pracical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
