use strict;
use warnings;
package RT::Extension::HistoryOnChange;

our $VERSION = '0.02';

=head1 NAME

RT-Extension-HistoryOnChange - Show history on ticket modify page

=head1 DESCRIPTION

Displays ticket history at the bottom of the the Basics page when you modify
values on a ticket.

=head1 RT VERSIONS

Works with RT 4.2.

=head1 INSTALLATION 

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item For RT 4.2.1, apply etc/history_on_change.diff

patch /path/to/rt/share/html/Ticket/Modify.html < etc/history_on_change.diff

Not needed for RT 4.2.2 and later.

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Set(@Plugins, qw(RT::Extension::HistoryOnChange));

or add C<RT::Extension::HistoryOnChange> to your existing C<@Plugins> line.
Starting with RT 4.2 you can also use:

    Plugin( "RT::Extension::HistoryOnChange" );

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

=head2 C<@HistoryOnChangeTransactionTypes>

By default, all history will be shown. You can limit the types of history
transactions displayed with this configuration option:

    Set(@HistoryOnChangeTransactionTypes, 'Create', 'Correspond');

Valid values are transaction types from the RT Transactions table. For
example, Create, Correspond, and Comment would get you all messages on the
ticket, but omit other transactions like added links (AddLink), status changes
(Status), etc.

This option changes only the history on the Modify (Basics) page. The main
ticket display history will continue to show the full history.

=head1 AUTHOR

sunnavy <sunnavy@bestpractical.com>

=head1 BUGS

All bugs should be reported via email to
L<bug-RT-Extension-HistoryOnChange@rt.cpan.org|mailto:bug-RT-Extension-HistoryOnChange@rt.cpan.org>
or via the web at
L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-HistoryOnChange>.


=head1 LICENSE AND COPYRIGHT

This software is Copyright 2014 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
