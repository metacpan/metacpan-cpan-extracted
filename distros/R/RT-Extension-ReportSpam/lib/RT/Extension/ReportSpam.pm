package RT::Extension::ReportSpam;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.00';

=encoding utf-8

=head1 NAME

RT::Extension::ReportSpam - mark tickets as spam with one click

=head1 DESCRIPTION

A simple extension that works with RT 4.0 and 4.2 which allows users
to report a ticket as a spam message.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::ReportSpam');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::ReportSpam));

or add C<RT::Extension::ReportSpam> to your existing C<@Plugins> line.

You may also want to set the C<$SpamAutoDeleteThreshold> config option to the
number of spam reports required before the system will automatically delete the
ticket.  This is useful if none of your users have DeleteTicket themselves, but
collectively they should be able to delete spam tickets for good.  Auto-delete
is disabled by leaving C<$SpamAutoDeleteThreshold> unset or setting it to 0.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 HOW TO …

=head2 Report Spam

On any ticket page, you can report the ticket as spam by clicking "S".

You can also click the "S" on the Tools → Spam → Recent page, which lists all
the recently created tickets with status "new" and without owner.

If you have rights to delete tickets you mark as spam, then they will be
deleted automatically at the same time.

=head2 Query All Tickets Reported as Spam

To find all tickets reported as spam and not deleted you can navigate to Tools
→ Spam → Reported, or use the query builder in advanced mode with the following
query:

    HasAttribute = 'SpamReports'

Both of these methods list the tickets reported as spam by others without
rights to delete tickets themselves.

=head2 Confirm a Ticket as Spam

You can confirm the reports by clicking "S" after querying all tickets reported
as spam.  If you have rights to delete tickets then they will be deleted.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-ReportSpam@rt.cpan.org|mailto:bug-RT-Extension-ReportSpam@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ReportSpam>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
