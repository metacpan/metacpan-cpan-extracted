use strict;
use warnings;
package RT::Extension::ExcelFeed;

our $VERSION = '1.00';

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

Works with RT 6.0. For RT 5.0 install the latest 0.* version.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Add this line to F</opt/rt6/etc/RT_SiteConfig.pm>

    Plugin('RT::Extension::ExcelFeed');

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

=over

=item C<$HideChartDownloadButton>

By default, a "Download as Microsoft Execel Spreadsheet" button is enabled
on Charts. You can disable it by adding the following config to your
RT_SiteConfig.pm:

    Set( $HideChartDownloadButton, 1 );

=back

=cut

if ( RT->Config->can('RegisterPluginConfig') ) {
    RT->Config->RegisterPluginConfig(
        Plugin  => 'ExcelFeed',
        Content => [
            {
                Name => 'HideChartDownloadButton',
                Help => 'https://metacpan.org/pod/RT::Extension::ExcelFeed#$HideChartDownloadButton',
            },
        ],
        Meta    => {
            HideChartDownloadButton => {
                Type   => 'SCALAR',
                Widget => '/Widgets/Form/Boolean',
            },
        }
    );
}

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-ExcelFeed@rt.cpan.org|mailto:bug-RT-Extension-ExcelFeed@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ExcelFeed>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2015-2025 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
