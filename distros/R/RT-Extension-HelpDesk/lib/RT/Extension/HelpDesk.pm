use strict;
use warnings;
package RT::Extension::HelpDesk;

our $VERSION = '1.00';

=head1 NAME

RT-Extension-HelpDesk - Default Help desk configuration for Request Tracker

=head1 RT VERSION

Works with RT 6.0.0 and newer. Install the latest 0.* version for older RTs.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt6/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::HelpDesk');

B<If you don't add the Plugin line and save, you will see errors in the next step.>

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

=item Restart your webserver

=back

=head1 DESCRIPTION

One common use for Request Tracker (RT) is tracking user issues,
typically related to IT services. The "help desk" is often a department,
either a designated help desk with many agents for large organizations,
or sometimes only a one or two people who handle all IT services for a
smaller organization.

RT is used to track incoming user requests so they don't get lost
and can be assigned to individual people to handle. It's also useful
for gathering general reporting on the volume of user IT requests
and what types of issues seem to generate the most issues.

This extension provides an L<initialdata|https://docs.bestpractical.com/rt/latest/initialdata.html/> file
to configure a queue with some sensible default rights configuration
for a typical help desk. Once installed, you can then edit the
configuration to best suit your needs.

A L<video is available|https://youtu.be/3Yuqh7zGBJ0> that shows a sample
RT with this extension installed and it should give you a good idea
what will be added to your RT.

=head2 Support Queue

After installing, you'll see a new queue called L<Support> for tracking
all of the incoming help desk requests. You can change the name to
anything you like after installing. In a typical configuration, you
will also want to assign an RT email address, like support@example.com
or helpdesk@example.com to create tickets in this queue.

=head2 Rights

Some typical initial rights are set on the L<Support> queue. The
system group "Everyone" gets a default set of rights to allow end
users to create tickets. Everyone is system group provided with RT,
and as the name implies it encompasses every user in RT.

=begin HTML

<p><img width="500px" src="https://static.bestpractical.com/images/helpdesk/everyone_group_rights.png"
alt="Group rights for 'Everyone' group on 'Support' queue" /></p>

=end HTML

These rights are usually the minimum needed for a typical support
desk. Anyone is able to write into our support address with a help
desk question, and they can reply and follow-up on that request if
we send them some questions.

The extension also grants "ShowTicket" to the Requestor role. If your
end users have access to RT's self service interface, this allows them
to see only tickets where they are the Requestor, which should be
the tickets they opened.

Our internal support representatives will need many more rights to
work on tickets. To make it easy to add and remove access for
staff users, this extension creates Support group. Rights are
granted to the group, so membership in the group is all a user needs
to get those rights.

=begin HTML

<p><img width="500px" src="https://static.bestpractical.com/images/helpdesk/support_group_rights.png"
alt="Group rights for 'Support' group on 'Support' queue" /></p>

=end HTML

=head2 Support Lifecycle

RT allows you to create and configure custom workflows for each queue
in the system.  In RT a ticket workflow is known as a L<Lifecycle|https://docs.bestpractical.com/rt/latest/customizing/lifecycles.html>.
This extension provies a custom lifecycle called "support" that
defines the various statuses a ticket can be in.

=begin HTML

<p><img width="500px" src="https://static.bestpractical.com/images/helpdesk/support_lifecycle.png"
alt="Lifecycle for 'Support' queue" /></p>

=end HTML

The custom statuses "waiting for customer" and "waiting for support"
trigger some automation around replying to support requests.

The automation applied to the support queue is designed to allow support staff
to more easily keep track of support requests that need attention. There are
two new Scrips that do the following:

=over

=item On Requestor Correspond Update Status To "waiting for support"

Updates the ticket status to "waiting for support" when a requestor replies
to a ticket. The requestor is typically the end user who is asking for
support.

=item On Non-Requestor Correspond Update Status To "waiting for customer"

Updates the ticket status to "waiting for customer" when a user
who is not a requestor on the ticket replies on the ticket. This usually means
the support representative in charge of the ticket sent an email to the customer
and is waiting for some feedback.

=back

=head2 Custom Fields

RT allows you to define custom fields on tickets, which can be anything you
need to record and track. This extension provides two common to a help desk,
Severity and Service Impacted.

Severity is a dropdown with typical High, Medium, Low values. As an RT admin,
you can change these values or add to them at Admin > Custom Fields, then
click on Severity.

Service Impacted is an autocomplete type field, which means users can type in
the box and if there is a defined value, it will autocomplete in a menu below
the field. If the user needs to add a value that hasn't been used before,
they can type in a completely new value. If you would prefer this to be a
dropdown like Severity, you can change this in the admin section also.

=head2 Support Dashboard

This extension creates a dashboard called "Support", accessible to any
member of the Support Group. This dashboard has a default saved search
called "Highest severity tickets waiting on support".

As the name suggests, this saved search shows all tickets waiting for
support and displays them in order by severity, so the most important
will be at the top.

=head2 Next Steps

This extension provides a good starting point and you can start using it
right away. Here are some additional things you can do to customize your
configuration:

=over

=item *

Create new user accounts for other staff and add them to the Support
Group. You might also remove the root user if that user account won't
be involved in support.

=item *

Update the custom fields Severity and Service Impacted, changing the
values in the dropdowns or adding other custom fields that better fit
your system.

=item *

Edit your templates to customize the default messages you send to users.
You can find templates at Admin > Global > Templates. For example,
the "Autoreply in HTML" is the default template that goes to users when
they open a ticket.

=item *

Users working primarily in support can edit their preferences and set Support
as their default queue.

=item *

Users can select Reports > Update this menu and add the Support dashboard to
their reports menu. The RT administrator can do this for all users as well.

(In RT 4.4, the menu is Home > Update this menu.)

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-HelpDesk@rt.cpan.org">bug-RT-Extension-HelpDesk@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-HelpDesk">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-HelpDesk@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-HelpDesk

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021-2025 by Best Practical LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
