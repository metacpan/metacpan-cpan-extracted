package RT::Extension::QuickCalls;
use warnings;
use strict;

our $VERSION = '1.04';

=head1 NAME

RT::Extension::QuickCalls - Quickly create tickets in specific queues with default values

=head1 RT VERSION

Works with RT 4.4, 5.0

To use the QuickCreate option RT must be newer than 4.4.1

=head1 DESCRIPTION

This RT extension allows you to add a QuickCalls portlet to your RT
dashboards.

You can configure the portlet to show the same Quick Calls on every
dashboard or customize the Quick Calls per dashboard.

The QuickCalls portlet can also be added to the user summary page:

    Set(@UserSummaryPortlets, (qw/ExtraInfo CreateTicket ActiveTickets
        InactiveTickets UserAssets QuickCalls/));

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item To use the QuickCreate option apply this patch for RT earlier than 5.0.6

    patch -d /opt/rt5 -p1 < patches/0001-Support-QuickCreate-to-pass-arguments-to-redirect-UR.patch

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::QuickCalls');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

You will need to enable the new QuickCalls portlet with a line
like this in your F<RT_SiteConfig.pm> file:

    Set($HomepageComponents, [qw(QuickCreate Quicksearch MyAdminQueues MySupportQueues MyReminders
                                 RefreshHomepage QuickCalls)]);

This is the default portlet list with QuickCalls added to the end
People can then choose to add the portlet to their homepage
in Preferences -> RT at a glance

=head2 BASIC CONFIGURATION

To set up your Quick Calls, you will want to specify a C<Name> and a
C<Queue> in the config file.  The C<Name> will become the C<Subject> of
the task unless you specify a C<Subject> option.  You can add other
Ticket options as needed, such as C<Status>.  Additionally, if the
C<SetOwnerToCurrentUser> option is set, the ticket will be owned by the
current user.

The following configuration will show the same Quick Calls on all
dashboards:

    Set(
        $QuickCalls, [
            { Name => "Foo", Queue => 'General', Status => 'resolved' },
            { Name => "Bar", Queue => 'Queue2',  Status => 'resolved' },
        ]
    );

=begin HTML

<p><img width="500px" src="https://static.bestpractical.com/images/quickcalls/QuickCallsScreenshot01.png" alt="Basic Configuration" /></p>

=end HTML

=head2 CUSTOM CONFIGURATION PER DASHBOARD

If you would like different dashboards to show different Quick Calls you
can use a different configuration format:

    Set(
        $QuickCalls, {
            Default => {
                Actions => [
                    { Name => "Default Foo", Queue => 'General', Status => 'resolved' },
                    { Name => "Default Bar", Queue => 'Queue2',  Status => 'resolved' }
                ],
            },
            1 => { # use the ID of the Dashboard as the hash key
                Title => 'Optional Title',
                Actions => [
                    { Name => "Dashboard ID 1 Foo", Queue => 'General', Status => 'resolved' },
                    { Name => "Dashboard ID 1 Bar", Queue => 'Queue2',  Status => 'resolved' }
                ],
            },
            ...
        }
    );

The above configuration would show different Quick Calls when the
portlet is loaded on the Dashboard with ID 1. If there is not a custom
configuration for a Dashboard ID it will use the 'Default' value.

=begin HTML

<p><img width="500px" src="https://static.bestpractical.com/images/quickcalls/QuickCallsScreenshot02.png" alt="Basic Configuration" /></p>

=end HTML

=head2 SUBREF VALUES

If a value is an anonymous subref, it will be called when the Quick Call
is selected, and its return value filled in for the appropriate key:

    Set(
        $QuickCalls, [
            {
                Queue   => 'General',
                Name    => 'This will have the current time on the server in its content',
                Content => sub {
                    my $date = localtime;
                    return "When: $date\n\n";
                },
            },
        ]
    );

=head2 QUICK CREATE

After you have added the QuickCalls portlet to your home page, you will
be able to select one, click Create and be brought to the ticket
creation page with multiple fields pre-filled.

If you would like the Quick Call to automatically create the ticket and
stay on the dashboard you can use the QuickCreate option:

    Set(
        $QuickCalls, [
            { Name => "Foo", Queue => 'General', Status => 'resolved', QuickCreate => 1 },
            { Name => "Bar", Queue => 'Queue2',  Status => 'resolved' },
        ]
    );

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-QuickCalls@rt.cpan.org|mailto:bug-RT-Extension-QuickCalls@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-QuickCalls>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014-2023 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
