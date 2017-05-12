use strict;
use warnings;
package RT::Extension::DeactiveActionPref;

our $VERSION = '0.01';

use RT::Config;
$RT::Config::META{DeactiveAction} = {
    Section         => 'Ticket composition',      #loc
    Overridable     => 1,
    SortOrder       => 10,
    Widget          => '/Widgets/Form/Select',
    WidgetArguments => {
        Description => 'Action of links to change tickets to inactive status?', #loc
        Values      => [qw(Respond Comment)], #loc
    },
};

=head1 NAME

RT-Extension-DeactiveActionPref - Deactive action user pref

=head1 DESCRIPTION

This extension allow user to specify the action (Respond or Comment) of
links that change a ticket to an inactive status, e.g. the default
"Resolve" and "Reject" links.

=head1 RT VERSION

Works with RT 4.2

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::DeactiveActionPref');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-DeactiveActionPref@rt.cpan.org|mailto:bug-RT-Extension-DeactiveActionPref@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-DeactiveActionPref>.

=head1 COPYRIGHT

This extension is Copyright (C) 2014 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
