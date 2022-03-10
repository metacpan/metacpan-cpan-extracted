use strict;
use warnings;
package RT::Extension::SelfServiceSimpleSearch;

our $VERSION = '1.02';

=head1 NAME

RT-Extension-SelfServiceSimpleSearch - Adds Simple Search to SelfService

=head1 DESCRIPTION

This adds RT's standard Simple Search interface to the SelfService
portal.  This is useful if unprivileged requestors are given passwords,
and the Requestor or Cc roles are granted the C<ShowTicket> right; it
allows those users to search through their tickets more effectively than
the stock SelfService pages do.

=head1 RT VERSION

Works with RT 4 and 5.0.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::SelfServiceSimpleSearch');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-SelfServiceSimpleSearch@rt.cpan.org|mailto:bug-RT-Extension-SelfServiceSimpleSearch@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-SelfServiceSimpleSearch>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014-2022 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
