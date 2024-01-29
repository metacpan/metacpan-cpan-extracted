use v5.10.1;
use strict;
use warnings;

package RT::Extension::PreviewInSearch;

our $VERSION = '0.06';

=head1 NAME

RT::Extension::PreviewInSearch - preview tickets right from search results page

=head1 DESCRIPTION

RT's query builder (the ticket search interface) allows you to customize
all of the columns that show up in search results, so you can usually
customize a search and get all of the ticket metadata you need displayed
on the search results page (e.g., current status, queue, owner, etc.). But
sometimes you also need to see something from the history when you are looking
for a ticket. This extension allows you to view the history of tickets at the
bottom of the search results page without clicking over to the full display
ticket page.

=for html <p><img src="https://raw.github.com/bestpractical/rt-extension-previewinsearch/master/doc/images/preview-screenshot.png" alt="History Preview in Search Results" /></p>

With the extension installed, perform your search, then click anywhere in the
ticket row in the search results. The history for that ticket will be displayed
at the bottom of the page. With RT 5, if you have inline edit enabled for
some search fields, click anywhere outside the inline edit fields. You'll
see the pencil icon appear if you are in an inline edit area.

To make it easier to see the ticket history with less scrolling, you can set
the Rows per page setting on the search to a smaller number. A L</$SideBySidePreview>
mode is also available.

=head1 RT VERSIONS

Works with RT 4.2, 4.4, 5.0

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Patch RT

For RT 5 prior to 5.0.6, apply the patches:

    patch -d /opt/rt5 -p1 < 0001-Add-ModifyPaths-Callback.patch

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin( "RT::Extension::PreviewInSearch" );

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=cut

=head1 CONFIGURATION

=head2 C<$SideBySidePreview>

Set this option to divide the search results page in half and
display the selected ticket history on the right of search results.

    Set($SideBySidePreview, 1);

=head1 AUTHOR

Best Practical Solutions, LLC

=head1 BUGS

All bugs should be reported via email to

L<bug-RT-Extension-PreviewInSearch@rt.cpan.org|mailto:bug-RT-Extension-PreviewInSearch@rt.cpan.org>

or via the web at

L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-PreviewInSearch>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2007-2023 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
