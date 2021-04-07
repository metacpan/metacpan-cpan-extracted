use 5.008003;
use strict;
use warnings;

package RT::Extension::CustomField::HideEmptyValues;

our $VERSION = '1.11';

=head1 NAME

RT::Extension::CustomField::HideEmptyValues - don't show custom fields without values

=head1 DESCRIPTION

It's sometimes desirable to hide custom fields without values in the UI
of Request Tracker when you view a ticket or another object.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::CustomField::HideEmptyValues');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::CustomField::HideEmptyValues));

or add C<RT::Extension::CustomField::HideEmptyValues> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-CustomField-HideEmptyValues@rt.cpan.org|mailto:bug-RT-Extension-CustomField-HideEmptyValues@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-CustomField-HideEmptyValues>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2009-2021 by Best Pracical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
