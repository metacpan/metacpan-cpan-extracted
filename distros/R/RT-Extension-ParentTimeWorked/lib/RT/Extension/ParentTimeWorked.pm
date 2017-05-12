use warnings;
use strict;

package RT::Extension::ParentTimeWorked;

our $VERSION = "1.02";

1;
__END__

=head1 NAME

RT::Extension::ParentTimeWorked - add TimeWorked to parent

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

    Plugin('RT::Extension::ParentTimeWorked');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::ParentTimeWorked));

or add C<RT::Extension::ParentTimeWorked> to your existing C<@Plugins> line.

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-ParentTimeWorked@rt.cpan.org|mailto:bug-RT-Extension-ParentTimeWorked@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ParentTimeWorked>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2012-2014 by Best Practical Solutions, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
