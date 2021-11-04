use strict;
use warnings;

package RT::Extension::TemplateTickets;

our $VERSION = '0.02';

=head1 NAME

RT::Extension::TemplateTickets - Designate tickets as templates for new tickets

=head1 DESCRIPTION

This extension allows a Request Tracker administrator to mark any ticket as
a I<template ticket> for privileged users to load when creating new tickets,
and optionally restrict access to these templates to specific groups.

When a queue has template tickets which are visible to the current user, a
drop-down list of available templates will be shown at the top of the ticket
creation form.  Choosing one of these will redisplay the form with the
template values pre-populated.

Tickets which have been created from a template will optionally show the
name of the template they were created from under their I<Basics> section,
if the template is configured to enable this.

For each template ticket, the administrator chooses which of the ticket's
properties to be include in the template, whether to include child tickets,
and which child ticket properties to carry over.

When a template ticket is used to create a new ticket, if the template had
child tickets, the creation of the new ticket will also trigger automatic
creation of child tickets patterned after those of the template's children. 
This helps with standardised tasks which need to be broken up into pieces.

Template tickets are administered under I<Admin> - I<Queues>; after choosing
a queue, go to I<Templates> - I<Tickets> in the page menu.  Administrators
must have the new B<ShowTicketTemplate> or B<ModifyTicketTemplate> rights.

B<Note:> Anyone using a template ticket to create a new ticket will need
sufficient rights to be able to view the original template ticket itself.

=head1 RT VERSION

Known to work with RT 4.2.16, 4.4.4, and 5.0.1.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions.

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::TemplateTickets');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your web server

=back

=head1 TUTORIAL

This tutorial goes through two example types of request:

=over

=item 1.

A request for a standardised change to be made to a system;

=item 2.

A data subject access request, which requires reports to be run by multiple
different teams.

=back

In this tutorial, we will refer to the RT groups I<Group 1>, I<Group 2>, and
I<Group 3>, and the queues I<General>, I<Team 1>, and I<Team 2>.  We will
also use the custom fields I<Systems affected> and I<Implementation plan>
for the change request scenario.  These are all just for illustration.

=head2 GETTING STARTED

Managers of template tickets will need the B<ShowConfigTab> right so they
can get to the I<Admin> - I<Queues> menu.

They will also need new rights; to create, edit, and delete template
tickets, they need the new I<Staff> right B<ModifyTicketTemplate> on the
relevant queue.  To just view the list of templates and their settings, they
only need the B<ShowTicketTemplate> right.

Grant these rights in the usual way through the queue's I<Group Rights> and
I<User Rights> pages.

Template tickets for a queue are managed under I<Admin> - I<Queues>; after
choosing a queue, go to I<Templates> - I<Tickets> in the page menu. 

=head2 SIMPLE TEMPLATES

Template tickets, as their name suggests, are based on tickets.  To create a
new template ticket, you must start with a ticket to base it on.

For the first example, consider a change request process.  Here, someone who
wants to make a change which may affect business functions will submit a
standardised form to change management, who will review it, and who will
then communicate the potential effects to the wider business.

The same sort of change may need to be raised many times.  For instance,
uninterruptible power supplies (UPS) need testing regularly.  There is a
risk of an outage when testing a UPS, so a change request would be needed
for each one.

Create a ticket with yourself as the requestor, with the subject of I<UPS
test - HOSTNAME>.  Populate the I<Systems affected> and I<Implementation
plan> custom fields with some placeholder text.  Then, resolve the ticket,
and make a note of its ticket number.

Now that you have a ticket to turn into a template:

=over

=item 1.

Go to I<Admin> - I<Queues>, click on the queue, and then go to
I<Templates> - I<Tickets> in the page menu.

=item 2.

Under the I<Create a new template ticket> heading, type the ticket number
into the box and click on the B<Create> button.

=item 3.

The template configuration page shows the settings at the top, and a view of
the ticket itself underneath.  In the top section, under I<Settings>, enter
a category.

Categories are optional, but useful when you have a lot of templates. 
Templates in the same category are grouped together when shown in the list.

=item 4.

Enter a description.  The description is shown next to the drop-down list
when the template is selected.  It is optional, but can be used to give more
details of what the template is to be used for.

=item 5.

Choose whether to show the derivation of tickets which use this template. 
When this is selected, new tickets raised using this template will have a
I<Derived from template:> field in their I<Basics> section, which will show
the ticket ID, subject, and description of this template.

=item 6.

In this example, there won't be any child tickets to include.

=item 7.

When no groups are selected under I<Groups>, this template can be used by
any privileged user with permission to see the ticket and create tickets in
the queue.

To restrict this template to RT groups I<Group 1> and I<Group 2>, type
"Group 1" into the box and click on the B<Add group> button, then type
"Group 2" into the box and click on the B<Add group> button again.

Click on the B<Remove> button to remove a group if it should not be there. 
Try adding another group and removing it.

=item 8.

Choose which fields from the template ticket to copy into any new ticket
which uses this template.

By default, only I<Subject> and I<Content> are selected (where I<Content>
refers to the opening correspondence - the first comment).

In this example, scroll down and also select the I<Systems affected> and
I<Implementation plan> fields.

=item 9.

Click on the B<Create ticket template> button.

=back

Once the template ticket has been set up, it will appear in the list under
this queue's I<Templates> - I<Tickets> page menu, from which you can edit it
again.

To delete a template ticket, edit it, and use the B<Delete this template
ticket> button at the right.  Check the confirmation box first.  Note that
the underlying ticket won't be deleted, just the template definition
attached to it.

=head2 USING A TEMPLATE

Once a template has been set up, members of the relevant groups will be able
to use it.

Click on the B<Create new ticket> button at the top of RT as usual.

Assuming that you are in the right group to see the template, you will see
I<Load defaults from template:> above the ticket creation form.  Choose the
template from the drop-down list, and click on the B<Load> button.  You will
see that the description is shown to the right of the button when you make a
selection.

After clicking on the B<Load> button, the ticket creation page is
redisplayed, with the relevant fields pre-populated.  In this example, you
would replace I<HOSTNAME> in the subject line with the hostname of the UPS
being tested.

Complete the form and click on the B<Create> button as usual.

=head2 TEMPLATES WITH CHILD TICKETS

For the second example, consider a data subject access request (DSAR). This
is a request from a customer for details of the information the company
holds on them.

Here, the person responsible for handling this request will raise an
internal ticket, with themselves as the requestor, and with one child ticket
for each team who has to run a report for their area of the business.  Once
each child ticket has been dealt with, the final report can be collated and
sent to the customer.

Create a ticket for the main DSAR request in the I<General> queue, with a
subject of I<DSAR #12345> and a message body saying something like "Full
details are in the usual secure location".  Then, create 2 child tickets
under it, in queues I<Team 1> and I<Team 2>, with subject lines I<Team 1
DSAR: {SUBJECT}> and I<Team 2 DSAR: {SUBJECT}>, and message bodies saying
something similar to the parent ticket.  Resolve all three tickets.

Now that you have the set of tickets to turn into a template:

=over

=item 1.

Go to I<Admin> - I<Queues>, click on the queue, and then go to
I<Templates> - I<Tickets> in the page menu.

=item 2.

Under the I<Create a new template ticket> heading, type the ticket number of
the first (parent) ticket into the box and click on the B<Create> button.

=item 3.

Enter a category and description, and choose whether to show the originating
template in new tickets, as before.

=item 4.

Enable the I<Child tickets> option, so that child tickets are included in
this template ticket.

You will see that an extra column, I<Child ticket fields>, appears to the
far right of the settings area.

=item 5.

Make this template available to the I<Group 3> group (in this example, the
team who process incoming DSARs would be the only members of this group). 
Do this by typing "Group 3" into the box under I<Groups> and clicking on the
B<Add group> button.

=item 6.

Select the appropriate template fields for the parent ticket, as usual.  In
this example we need at least I<Subject> and I<Content>.

=item 7.

Select the appropriate template fields for the child tickets.

By default, I<Queue>, I<Subject>, and I<Content> are selected for child
tickets.  If I<Queue> is not selected, the child tickets will all be created
in the same queue as the parent, which we don't want in this case.

When a child ticket is created as part of a template, the string
C<{SUBJECT}> is replaced with the parent's subject.

=item 8.

Click on the B<Create ticket template> button, as before.

=back

If you now create a ticket using this new template, then you will see that
two child tickets are automatically created, with subjects the same as
whatever you entered but prefixed by "Team 1 DSAR:" and "Team 2 DSAR:" - and
they will have been created in the relevant teams' queues.

=head1 AUTHOR

Andrew Wood

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-TemplateTickets@rt.cpan.org">bug-RT-Extension-TemplateTickets@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-TemplateTickets">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-TemplateTickets@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-TemplateTickets

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Andrew Wood

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

RT::Queue->AddRight(
    'Admin' => 'ShowTicketTemplate' => 'View ticket templates' );    # loc
RT::Queue->AddRight(
    'Admin' => 'ModifyTicketTemplate' => 'Modify ticket templates' );    # loc

1;
