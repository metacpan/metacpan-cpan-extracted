use utf8;
use strict;
use warnings;
no warnings qw(redefine);
package RT::Extension::GroupSummary;

our $VERSION = '0.01';

=encoding utf8

=head1 NAME

RT-Extension-GroupSummary - Display a summary of a group

=head1 DESCRIPTION

This module allows RT to display semantic information about any L<group|RT::Group>, mainly through CustomFields attached to this L<group|RT::Group>.

It displays information about a L<group|RT::Group> on a Group Summary page, similar to what is done about a L<user|RT::User>. A Group Summary page includes the name, the description and CustomFields of a group. The Group Summary page can be accessed from any tabs of C<Admin/Groups> and is linked to any display of a L<principal|RT::Principal> which is a L<group|RT::Group> (just like any display of a L<principal|RT::Principal> which is a L<user|RT::User> is linked to the related User Summary page).

This module also provides a Group Summary Search feature and links results to related Group Summary pages.

In a future revision, it is planned to use Portlets in a Group Summary page, just like in a User Summary page.

=head1 CONFIGURATION

Display of results from a Group Summary Search can be configured through the C<GroupSearchResultFormat>:

    Set($GroupSearchResultFormat,
         q{'<a href="__WebPath__/Group/Summary.html?id=__id__">__id__</a>/TITLE:#'}
        .q{,'<a href="__WebPath__/Group/Summary.html?id=__id__">__Name__</a>/TITLE:Name'}
        .q{,'__Description__/TITLE:Description'}
    );

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

    Plugin('RT::Extension::GroupSummary');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::GroupSummary));

or add C<RT::Extension::GroupSummary> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=cut

=head1 AUTHOR

Gérald Sédrati-Dinet E<lt>gibus@easter-eggs.comE<gt>

=head1 REPOSITORY

L<https://github.com/gibus/RT-Extension-GroupSummary>

=head1 BUGS

All bugs should be reported via email to

L<bug-RT-Extension-GroupSummary@rt.cpan.org|mailto:bug-RT-Extension-GroupSummary@rt.cpan.org>

or via the web at

L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-GroupSummary>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2017 by Gérald Sédrati-Dinet, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007

=cut

1;
