use strict;
use warnings;
package RT::Extension::ExcelFeed;

our $VERSION = '0.05';

=head1 NAME

RT-Extension-ExcelFeed

=head1 DESCRIPTION

This extenstion allows you to generate RT reports in MS Excel XSLX format.
It provides two ways to do this. First, it adds a new MS Excel option to
the 'Feeds' menu on the Query Builder search results page. It also adds
an option to the Dashboard subscription page that allows you to have scheduled
dashboards emailed to recipients as attached MS Excel files rather than
inline HTML reports.

=head1 RT VERSION

Works with RT 4.2, 4.4

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item patch RT

The following patches are also needed. Note the versions and only apply
the patches needed for your version.

Only run these the first time you install this module. If upgrading, install
any patches that were not previously applied.

Apply for both 4.2 and 4.4.0. Not needed for 4.4.1 or later:

    patch -p1 -d /path/to/rt < etc/subscription_callbacks.patch

Apply for 4.2 and 4.4.0. Not needed for 4.2.13 or later, or 4.4.1.

    patch -p1 -d /path/to/rt < etc/chart_callback.patch

Apply for 4.2:

    patch -p1 -d /path/to/rt < etc/tabs_privileged_callback.patch

Apply for 4.4:

    patch -p1 -d /path/to/rt < etc/tabs_privileged_callback_44.patch

=item Add this line to F</opt/rt4/etc/RT_SiteConfig.pm>

    Plugin('RT::Extension::ExcelFeed');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-ExcelFeed@rt.cpan.org|mailto:bug-RT-Extension-ExcelFeed@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ExcelFeed>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2015-2018 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
