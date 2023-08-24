use strict;
use warnings;

package RT::Extension::PinComment;

our $VERSION = '0.01';

=head1 NAME

RT::Extension::PinComment - Add a "pin comment" feature to tickets

=head1 DESCRIPTION

This extension adds the facility to pin a comment on a ticket, so it is
highlighted and always comes first in the transaction history.

As well as adding a "I<Pin>" action to ticket transactions, this extension
also provides a format field "I<PinComment>" in the query builder for
showing the contents of a ticket's pinned comment, and a search option
"I<Has a pinned comment>" to find tickets with pinned comments.

An operator requires the I<ModifyTicket> right on a ticket to change which
comment is pinned on it.

=head1 RT VERSION

Known to work with RT 4.2.16, 4.4.4, and 5.0.1.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions.

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::PinComment');

=item Restart your web server

=back

=head1 ISSUES AND CONTRIBUTIONS

The project is held on L<Codeberg|https://codeberg.org>; its issue tracker
is at L<https://codeberg.org/a-j-wood/rt-extension-pincomment/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright 2023 Andrew Wood.

License GPLv3+: GNU GPL version 3 or later: L<https://gnu.org/licenses/gpl.html>

This is free software: you are free to change and redistribute it.  There is
NO WARRANTY, to the extent permitted by law.

=cut

RT->AddStyleSheets('PinComment.css');

1;
