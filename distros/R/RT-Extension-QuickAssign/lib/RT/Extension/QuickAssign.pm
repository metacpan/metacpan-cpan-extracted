use strict;
use warnings;
package RT::Extension::QuickAssign;

our $VERSION = '1.01';

=head1 NAME

RT-Extension-QuickAssign - Add owner change links on ticket display page

=head1 DESCRIPTION

For tickets that are currently unowned, this extension provides an
"Assign..." menu under the Actions menu, allowing users with sufficient
rights to quickly assign the owner to any of the possible owners for a
ticket.

Generating the list of potential owners for a ticket may have a
performance impact for some installations.

=head1 RT VERSION

Works with RT 4.0, 4.2 and 4.4

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::QuickAssign');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::QuickAssign));

or add C<RT::Extension::QuickAssign> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-QuickAssign@rt.cpan.org|mailto:bug-RT-Extension-QuickAssign@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-QuickAssign>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014-2019 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
