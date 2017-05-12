use strict;
use warnings;
package RT::Extension::QuickAddTimeWorked;

our $VERSION = '0.01';

=head1 NAME

RT-Extension-QuickAddTimeWorked - Quick "add to time worked" entry on the ticket display page

=head1 INSTALLATION 

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Set(@Plugins, qw(RT::Extension::QuickAddTimeWorked));

or add C<RT::Extension::QuickAddTimeWorked> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Thomas Sibley <trs@bestpractical.com>

=head1 BUGS

All bugs should be reported via email to
L<bug-RT-Extension-QuickAddTimeWorked@rt.cpan.org|mailto:bug-RT-Extension-QuickAddTimeWorked@rt.cpan.org>
or via the web at
L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-QuickAddTimeWorked>.


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2013 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
