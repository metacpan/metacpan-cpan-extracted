use 5.008003;
use strict;
use warnings;

package RT::Extension::CustomFieldsOnUpdate;

our $VERSION = '1.02';

=head1 NAME

RT::Extension::CustomFieldsOnUpdate - edit ticket's custom fields on reply/comment

=head1 DESCRIPTION

This extension allows the update of tickets' custom fields on reply and
comment pages.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::CustomFieldsOnUpdate');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::CustomFieldsOnUpdate));

or add C<RT::Extension::CustomFieldsOnUpdate> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-CustomFieldsOnUpdate@rt.cpan.org|mailto:bug-RT-Extension-CustomFieldsOnUpdate@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-CustomFieldsOnUpdate>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2016 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
