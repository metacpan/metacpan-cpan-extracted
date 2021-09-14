# NAME

RT::Extension::TemplateTickets - Designate tickets as templates for new tickets

# DESCRIPTION

This extension allows a Request Tracker administrator to mark any ticket as
a _template ticket_ for privileged users to load when creating new tickets,
and optionally restrict access to these templates to specific groups.

When a queue has template tickets which are visible to the current user, a
drop-down list of available templates will be shown at the top of the ticket
creation form.  Choosing one of these will redisplay the form with the
template values pre-populated.

Tickets which have been created from a template will optionally show the
name of the template they were created from under their _Basics_ section,
if the template is configured to enable this.

For each template ticket, the administrator chooses which of the ticket's
properties to be include in the template, whether to include child tickets,
and which child ticket properties to carry over.

When a template ticket is used to create a new ticket, if the template had
child tickets, the creation of the new ticket will also trigger automatic
creation of child tickets patterned after those of the template's children. 
This helps with standardised tasks which need to be broken up into pieces.

Template tickets are administered under _Admin_ - _Queues_; after choosing
a queue, go to _Templates_ - _Tickets_ in the page menu.  Administrators
must have the new **ShowTicketTemplate** or **ModifyTicketTemplate** rights.

**Note:** Anyone using a template ticket to create a new ticket will need
sufficient rights to be able to view the original template ticket itself.

# RT VERSION

Known to work with RT 4.2.16, 4.4.4, and 5.0.1.

# INSTALLATION

- `perl Makefile.PL`
- `make`
- `make install`

    May need root permissions.

- Edit your `/opt/rt4/etc/RT_SiteConfig.pm`

    Add this line:

        Plugin('RT::Extension::TemplateTickets');

- Clear your mason cache

        rm -rf /opt/rt4/var/mason_data/obj

- Restart your web server

# TUTORIAL

This tutorial goes through two example types of request:

1. A request for a standardised change to be made to a system;
2. A data subject access request, which requires reports to be run by multiple
different teams.

In this tutorial, we will refer to the RT groups _Group 1_, _Group 2_, and
_Group 3_, and the queues _General_, _Team 1_, and _Team 2_.  We will
also use the custom fields _Systems affected_ and _Implementation plan_
for the change request scenario.  These are all just for illustration.

## GETTING STARTED

Managers of template tickets will need the **ShowConfigTab** right so they
can get to the _Admin_ - _Queues_ menu.

They will also need new rights; to create, edit, and delete template
tickets, they need the new _Staff_ right **ModifyTicketTemplate** on the
relevant queue.  To just view the list of templates and their settings, they
only need the **ShowTicketTemplate** right.

Grant these rights in the usual way through the queue's _Group Rights_ and
_User Rights_ pages.

Template tickets for a queue are managed under _Admin_ - _Queues_; after
choosing a queue, go to _Templates_ - _Tickets_ in the page menu. 

## SIMPLE TEMPLATES

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

Create a ticket with yourself as the requestor, with the subject of _UPS
test - HOSTNAME_.  Populate the _Systems affected_ and _Implementation
plan_ custom fields with some placeholder text.  Then, resolve the ticket,
and make a note of its ticket number.

Now that you have a ticket to turn into a template:

1. Go to _Admin_ - _Queues_, click on the queue, and then go to
_Templates_ - _Tickets_ in the page menu.
2. Under the _Create a new template ticket_ heading, type the ticket number
into the box and click on the **Create** button.
3. The template configuration page shows the settings at the top, and a view of
the ticket itself underneath.  In the top section, under _Settings_, enter
a category.

    Categories are optional, but useful when you have a lot of templates. 
    Templates in the same category are grouped together when shown in the list.

4. Enter a description.  The description is shown next to the drop-down list
when the template is selected.  It is optional, but can be used to give more
details of what the template is to be used for.
5. Choose whether to show the derivation of tickets which use this template. 
When this is selected, new tickets raised using this template will have a
_Derived from template:_ field in their _Basics_ section, which will show
the ticket ID, subject, and description of this template.
6. In this example, there won't be any child tickets to include.
7. When no groups are selected under _Groups_, this template can be used by
any privileged user with permission to see the ticket and create tickets in
the queue.

    To restrict this template to RT groups _Group 1_ and _Group 2_, type
    "Group 1" into the box and click on the **Add group** button, then type
    "Group 2" into the box and click on the **Add group** button again.

    Click on the **Remove** button to remove a group if it should not be there. 
    Try adding another group and removing it.

8. Choose which fields from the template ticket to copy into any new ticket
which uses this template.

    By default, only _Subject_ and _Content_ are selected (where _Content_
    refers to the opening correspondence - the first comment).

    In this example, scroll down and also select the _Systems affected_ and
    _Implementation plan_ fields.

9. Click on the **Create ticket template** button.

Once the template ticket has been set up, it will appear in the list under
this queue's _Templates_ - _Tickets_ page menu, from which you can edit it
again.

To delete a template ticket, edit it, and use the **Delete this template
ticket** button at the right.  Check the confirmation box first.  Note that
the underlying ticket won't be deleted, just the template definition
attached to it.

## USING A TEMPLATE

Once a template has been set up, members of the relevant groups will be able
to use it.

Click on the **Create new ticket** button at the top of RT as usual.

Assuming that you are in the right group to see the template, you will see
_Load defaults from template:_ above the ticket creation form.  Choose the
template from the drop-down list, and click on the **Load** button.  You will
see that the description is shown to the right of the button when you make a
selection.

After clicking on the **Load** button, the ticket creation page is
redisplayed, with the relevant fields pre-populated.  In this example, you
would replace _HOSTNAME_ in the subject line with the hostname of the UPS
being tested.

Complete the form and click on the **Create** button as usual.

## TEMPLATES WITH CHILD TICKETS

For the second example, consider a data subject access request (DSAR). This
is a request from a customer for details of the information the company
holds on them.

Here, the person responsible for handling this request will raise an
internal ticket, with themselves as the requestor, and with one child ticket
for each team who has to run a report for their area of the business.  Once
each child ticket has been dealt with, the final report can be collated and
sent to the customer.

Create a ticket for the main DSAR request in the _General_ queue, with a
subject of _DSAR #12345_ and a message body saying something like "Full
details are in the usual secure location".  Then, create 2 child tickets
under it, in queues _Team 1_ and _Team 2_, with subject lines _Team 1
DSAR: {SUBJECT}_ and _Team 2 DSAR: {SUBJECT}_, and message bodies saying
something similar to the parent ticket.  Resolve all three tickets.

Now that you have the set of tickets to turn into a template:

1. Go to _Admin_ - _Queues_, click on the queue, and then go to
_Templates_ - _Tickets_ in the page menu.
2. Under the _Create a new template ticket_ heading, type the ticket number of
the first (parent) ticket into the box and click on the **Create** button.
3. Enter a category and description, and choose whether to show the originating
template in new tickets, as before.
4. Enable the _Child tickets_ option, so that child tickets are included in
this template ticket.

    You will see that an extra column, _Child ticket fields_, appears to the
    far right of the settings area.

5. Make this template available to the _Group 3_ group (in this example, the
team who process incoming DSARs would be the only members of this group). 
Do this by typing "Group 3" into the box under _Groups_ and clicking on the
**Add group** button.
6. Select the appropriate template fields for the parent ticket, as usual.  In
this example we need at least _Subject_ and _Content_.
7. Select the appropriate template fields for the child tickets.

    By default, _Queue_, _Subject_, and _Content_ are selected for child
    tickets.  If _Queue_ is not selected, the child tickets will all be created
    in the same queue as the parent, which we don't want in this case.

    When a child ticket is created as part of a template, the string
    `{SUBJECT}` is replaced with the parent's subject.

8. Click on the **Create ticket template** button, as before.

If you now create a ticket using this new template, then you will see that
two child tickets are automatically created, with subjects the same as
whatever you entered but prefixed by "Team 1 DSAR:" and "Team 2 DSAR:" - and
they will have been created in the relevant teams' queues.

# AUTHOR

Andrew Wood

<div>
    <p>All bugs should be reported via email to <a
    href="mailto:bug-RT-Extension-TemplateTickets@rt.cpan.org">bug-RT-Extension-TemplateTickets@rt.cpan.org</a>
    or via the web at <a
    href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-TemplateTickets">rt.cpan.org</a>.</p>
</div>

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Andrew Wood

This is free software, licensed under:

    The GNU General Public License, Version 2, June 1991
