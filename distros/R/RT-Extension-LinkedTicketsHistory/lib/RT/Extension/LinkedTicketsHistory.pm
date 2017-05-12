use strict;
use warnings;
package RT::Extension::LinkedTicketsHistory;

our $VERSION = '0.02';

=head1 NAME

RT-Extension-LinkedTicketsHistory - show linked tickets' history on ticket display page

=head1 INSTALLATION 

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Set(@Plugins, qw(RT::Extension::LinkedTicketsHistory));

or add C<RT::Extension::LinkedTicketsHistory> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

=head2 C<@LinkedTicketsHistoryTransactionTypes>

By default, all history will be shown. You can limit the types of history
transactions displayed with this configuration option:

    Set(@LinkedTicketsHistoryTransactionTypes, 'Create', 'Correspond');

Valid values are transaction types from the RT Transactions table. For
example, Create, Correspond, and Comment would get you all messages on the
ticket, but omit other transactions like added links (AddLink), status changes
(Status), etc.

=head1 AUTHOR

sunnavy <sunnavy@bestpractical.com>

=head1 BUGS

All bugs should be reported via email to
L<bug-RT-Extension-LinkedTicketsHistory@rt.cpan.org|mailto:bug-RT-Extension-LinkedTicketsHistory@rt.cpan.org>
or via the web at
L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-LinkedTicketsHistory>.


=head1 LICENSE AND COPYRIGHT

This software is Copyright 2013 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
