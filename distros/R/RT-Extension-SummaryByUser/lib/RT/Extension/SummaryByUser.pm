package RT::Extension::SummaryByUser;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.01';

=head1 NAME

RT::Extension::SummaryByUser - portlets to show ticket counters per user

=head1 DESCRIPTION

This extension ships with F<OwnerSummary> and F<RequestorSummary> portlets
you can use in a dashboard and/or RT at glance. Summary can be displayed
not only by user, but by users' organization or other fields. For example
RequestorSummary portlet displays summary by requestors' organization.
Read more about this below in L</CONFIGURATION> section.

=head1 VERSION

This module works on RT 4.0.  It is not currently compatible with RT
4.2.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Set(@Plugins, qw(RT::Extension::SummaryByUser));

or add C<RT::Extension::SummaryByUser> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

To make a F<OwnerSummary> or F<RequestorSummary> available in the Web UI
you B<must register> it in the RT config using C<$HomepageComponents>
option. Once a portlet is registered in C<$HomepageComponents> it can be
added to your homepage using the Edit link on RT at a Glance, or added
to a Dashboard.

More portlets can be created using this extension. Look into the
F<RequestorSummary> file, it just calls F<OwnerSummary> with arguments:

    <%INIT>
    return $m->comp( 'OwnerSummary', Role => 'Requestor', Field => 'Organization' );
    </%INIT>

As you can see there is two arguments: 'Role' and 'Field'. Role can be 'Owner',
'Creator', 'Requestor', 'Cc' and 'AdminCc'. Field can be any column from Users
table or empty. The following fields make sence: 'Organization', 'Country', 'State'
or 'City'. Empty value means that the report is groupped by particular users.

You can copy this file into F<local/html/Elements> directory with different name,
for example with F<RequestorCountrySummary>, change arguments, register the new
portlet in C<$HomepageComponents>, restart server and use new portlet.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-SummaryByUser@rt.cpan.org|mailto:bug-RT-Extension-SummaryByUser@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-SummaryByUser>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
