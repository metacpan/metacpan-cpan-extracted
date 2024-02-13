use strict;
use warnings;

package RT::Extension::NewTicketFromCorrespondence;

our $VERSION = '0.04';

=head1 NAME

RT::Extension::NewTicketFromCorrespondence - Make new tickets from correspondence

=head1 DESCRIPTION

This extension adds a "I<Split Off>" action item to inbound correspondence
items in ticket history, which allows the operator to create a new ticket,
linked to the current one, based on that transaction.

When a ticket requestor replies to their open ticket with a new issue
instead of creating a new ticket, this "I<Split Off>" action allows the
ticket owner to create a new ticket on the requestor's behalf, including the
correspondence automatically.

Using this action opens the ticket creation form, with the correspondence
already included in the message box and the requestor set to the sender, and
with a "referred to by" link back to the original ticket.  The operator can
then adjust the message as necessary before creating the new ticket.

The action is only available to operators who have I<CreateTicket> rights on
the ticket's queue and I<ModifyTicket> rights on the ticket.

=head1 RT VERSION

Known to work with RT 4.2.16, 4.4.4, and 5.0.1.

=head1 INSTALLATION

=over

=item C<PREFIX=/opt/rt5/local perl Makefile.PL>

Adjust I<PREFIX> to point to your RT "local" directory.

=item C<make>

=item C<make install>

May need root permissions.

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::NewTicketFromCorrespondence');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your web server

=back

=head1 ISSUES AND CONTRIBUTIONS

The project is held on Codeberg - https://codeberg.org - and its issue tracker
is at: https://codeberg.org/a-j-wood/rt-extension-newticketfromcorrespondence/issues

=head1 LICENSE AND COPYRIGHT

Copyright 2023-2024 Andrew Wood.

License GPLv3+: GNU GPL version 3 or later: https://gnu.org/licenses/gpl.html

This is free software: you are free to change and redistribute it.  There is
NO WARRANTY, to the extent permitted by law.

=cut

1;
