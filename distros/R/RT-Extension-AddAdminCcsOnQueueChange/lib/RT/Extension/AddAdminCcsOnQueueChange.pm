use strict;
use warnings;
package RT::Extension::AddAdminCcsOnQueueChange;

our $VERSION = '1.00';

=head1 NAME

RT-Extension-AddAdminCcsOnQueueChange - Keep AdminCcs in the loop

=head1 DESCRIPTION

This extension adds a new action, C<Add Queue AdminCcs to Ticket>, as
well as a global scrip using it, which copies over Queue AdminCcs to the
ticket when it is moved between queues.  This ensures that the previous
queue's AdminCcs are still notified of changes to the ticket, and
potentially granted rights as well.

Install this extension if you have multiple queues with differing sets
of AdminCcs, move tickets between queues often, and want the old queue's
AdminCcs to be kept updated after it is moved.

=head1 RT VERSION

Works with RT 4.0 and 4.2.

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

    Plugin('RT::Extension::AddAdminCcsOnQueueChange');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::AddAdminCcsOnQueueChange));

or add C<RT::Extension::AddAdminCcsOnQueueChange> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-AddAdminCcsOnQueueChange@rt.cpan.org|mailto:bug-RT-Extension-AddAdminCcsOnQueueChange@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-AddAdminCcsOnQueueChange>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2015 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
