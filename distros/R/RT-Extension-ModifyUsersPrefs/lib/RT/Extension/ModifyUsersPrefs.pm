use utf8;
use strict;
use warnings;
no warnings qw(redefine);
package RT::Extension::ModifyUsersPrefs;

our $VERSION = '0.01';

=encoding utf8

=head1 NAME

RT::Extension::ModifyUsersPrefs - Allow to modify other users' preferences

=head1 DESCRIPTION

By default, RT only allows authorized users to modify their own preferences. This module adds the ability to modify other users' preferences, by adding a new tab in C<Admin/Users> pages.

This implies that C<AdminUsers> and C< ShowConfigTab> rights should be granted in order to be authorized to modify other users' preferences.

=back

=head1 RT VERSION

Works with RT 4.2 or greater

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::ModifyUsersPrefs');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::ModifyUsersPrefs));

or add C<RT::Extension::ModifyUsersPrefs> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=cut

=head1 AUTHOR

Gérald Sédrati-Dinet E<lt>gibus@easter-eggs.comE<gt>

=head1 REPOSITORY

L<https://github.com/gibus/RT-Extension-ModifyUsersPrefs>

=head1 BUGS

All bugs should be reported via email to

L<bug-RT-Extension-ModifyUsersPrefs@rt.cpan.org|mailto:bug-RT-Extension-ModifyUsersPrefs@rt.cpan.org>

or via the web at

L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ModifyUsersPrefs>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2017 by Gérald Sédrati-Dinet, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007

=cut

1;
